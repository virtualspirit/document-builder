# frozen_string_literal: true

module Document
  module Concerns
    module Models
      module ActiveStorageBridge
        # Provides the class-level DSL for declaring that an Active Entity model has attached blobs.
        module Attached
          module Macros
            class ActsAsUploadableConfig

              attr_accessor :fieldname, :belongs_to_owner, :validations, :processors, :metadata, :processing_state

              def initialize **args
                default_args = {
                  fieldname: :file,
                  validations: {
                    presence: false,
                    max_file_size: false,
                    whitelist: false
                  },
                  metadata: true
                }.merge(args)
                default_args.each do |key,val|
                  if respond_to?("#{key}=")
                    send("#{key}=", val)
                  end
                end
              end

              def merge! args
                args.each do |key,val|
                  if respond_to?("#{key}=")
                    send("#{key}=", val)
                  end
                end
              end

            end
            module ActsAsUploadable
              extend ActiveSupport::Concern

              class_methods do

                def acts_as_uploadable *args
                  include ActsAsUploadableClassMethods
                  include ActsAsUploadableInstanceMethods
                  options  = args.extract_options!
                  fields = args.flatten

                  fields.each do |field|
                    unless options.blank?
                      uploadable_config_merge! fieldname: field, config: options
                    end
                    _validations = uploadable_validations fieldname: field
                    if (_validations.is_a?(Hash))
                      if _validations[:presence]
                        validates field, presence: true
                      end
                    end
                    include Document.file_uploader_class.new(field)

                    _meta = uploadable_metadata(fieldname: field)

                    if _meta
                      field "#{field}_metadata", type: Hash
                      before_validation do
                        send("#{field}_metadata=", {}) if send("#{field}_metadata").nil?
                      end
                      after_initialize do
                        send("#{field}_metadata=", {}) if send("#{field}_metadata").nil?
                      end
                    end

                  end

                end

              end

              module ActsAsUploadableClassMethods
                extend ActiveSupport::Concern
                included do
                  class_attribute :_uploadable_config
                  self._uploadable_config = {}
                end

                class_methods do

                  def uploadable_config_merge! fieldname:, config: {}
                    current_config = uploadable_config fieldname: fieldname
                    current_config.merge!(config)
                    self._uploadable_config[self.name][fieldname] = current_config
                  end

                  def uploadable_config fieldname:, key: nil
                    if self._uploadable_config[self.name].nil?
                      self._uploadable_config[self.name] = {}
                    end
                    if self._uploadable_config[self.name][fieldname.to_sym].nil?
                      self._uploadable_config[self.name][fieldname.to_sym] = ActsAsUploadableConfig.new
                    end
                    if(key)
                      return self._uploadable_config[self.name][fieldname.to_sym].send(key)
                    else
                      return self._uploadable_config[self.name][fieldname.to_sym]
                    end
                  end

                  def uploadable_validations fieldname:, validations: nil
                    if validations
                      uploadable_config(fieldname: fieldname).validations= validations
                    end
                    uploadable_config(fieldname: fieldname).validations
                  end

                  def uploadable_metadata fieldname:, metadata: nil
                    if metadata
                      uploadable_config(fieldname: fieldname).metadata= metadata
                    end
                    uploadable_config(fieldname: fieldname).metadata
                  end

                end
              end

              module ActsAsUploadableInstanceMethods
                extend ActiveSupport::Concern

                def whitelist fieldname
                  _validations = self.class.uploadable_validations(fieldname: fieldname)
                  _validations.is_a?(Hash) ? _validations[:whitelist] : false
                end

                def max_file_size fieldname
                  _validations = self.class.uploadable_validations(fieldname: fieldname)
                  _validations.is_a?(Hash) ? _validations[:max_file_size] : false
                end

                def mime_type
                  self.metadata['mime_type']
                end

                def filetype
                  self.mime_type.split('/')[0] if self.mime_type
                end

                def has_versions?
                  self.file.is_a?(Hash) ? true : false
                end

                def reluctant_file(version = nil)
                  if self.has_versions? && version.blank?
                    self.file[self.file.keys.first]
                  elsif self.has_versions? && !version.blank?
                    self.file[version].blank? ? self.file[self.file.keys.first] : self.file[version]
                  else
                    self.file
                  end
                end

                private

                  def set_mime_type
                    self.metadata = {} if self.metadata.nil?
                    self.metadata['mime_type'] = self.reluctant_file.mime_type
                  end

              end

            end

            extend ActiveSupport::Concern

            module ClassMethods

              def has_one_attached(name)

                field "#{name}_data", type: String

                unless included_modules.include?(ActsAsUploadable)
                  include ActsAsUploadable
                end
                acts_as_uploadable name, metadata: true

                class_eval <<-CODE, __FILE__, __LINE__ + 1
                  def #{name}=(attachable)
                    blob =
                      case attachable
                        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
                          attachable.tempfile.open if attachable.tempfile.closed?
                          attachable
                        when Hash
                          if attachable.keys.uniq.sort == ["filename", "type", "name", "tempfile", "head"].sort
                            attachable= ActionDispatch::Http::UploadedFile.new(attachable)
                            if attachable.tempfile.closed?
                              attachable.open
                             end
                          end
                          attachable
                      end
                    super(blob)
                  end
                CODE
              end

              def has_many_attached(name)
                class_eval <<-CODE, __FILE__, __LINE__ + 1
                  def #{name}=(attachables)
                    blobs =
                      attachables.flatten.collect do |attachable|
                        case attachable
                        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
                          attachable.tempfile.open if attachable.tempfile.closed?
                          attachable
                        when Hash
                          if attachable.keys.uniq.sort == ["filename", "type", "name", "tempfile", "head"].sort
                            file= ActionDispatch::Http::UploadedFile.new(attachable)
                            if file.tempfile.closed?
                              file.temp_file.open
                              file
                            else
                              file
                            end
                          end
                        end
                      end
                    blobs = blobs.map{|blob| #{name}.build(attachment: blob) }
                    blobs
                  end
                CODE
              end

            end
          end
        end
      end
    end
  end
end

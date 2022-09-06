# frozen_string_literal: true

module Document
  module Concerns
    module Models
      module ActiveStorageBridge
        # Provides the class-level DSL for declaring that an Active Entity model has attached blobs.
        module Attached
          module Macros
            extend ActiveSupport::Concern

            module ClassMethods

              def has_one_attached(name)

                field "#{name}_data", type: String

                unless included_modules.include?(Support::Uploadable::Models::Concerns::ActsAsUploadable)
                  include Support::Uploadable::Models::Concerns::ActsAsUploadable
                end
                acts_as_uploadable name, metadata: false, ranked: false, processing_state: false, belongs_to_owner: false

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

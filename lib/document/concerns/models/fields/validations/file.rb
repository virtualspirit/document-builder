module Document
  module Concerns
    module Models
      module Fields
        module Validations
          module File
            extend ActiveSupport::Concern

            included do
              embeds_one :file, class_name: "Document::Concerns::Models::Fields::Validations::File::FileOptions"
              accepts_nested_attributes_for :file

              after_initialize do
                build_file unless file
              end
            end

            def interpret_to(model, field_name, accessibility, options = {})
              super
              file&.interpret_to model, field_name, accessibility, options
            end

            class FileOptions < FieldOptions
              attribute :whitelist, :string, array: true, default: []
              attribute :max_file_size, :integer, default: 0
              attribute :file_size_unit, :string, default: "bytes"

              enum file_size_unit: {
                bytes: "bytes",
                kilobytes: "kilobytes",
                megabytes: "megabytes"
              }, _prefix: :file_size_unit

              def interpret_to(model, field_name, _accessibility, _options = {})
                options = {}
                options[:whitelist] = whitelist
                options[:max_file_size] = max_file_size
                options[:file_size_unit] = file_size_unit
                options[:max_file_size_in_bytes] = max_file_size_in_bytes
                options.symbolize_keys!
                model.validates_with FileContentTypeValidator, _merge_attributes([field_name, options])
              end

              def max_file_size_in_bytes
                if max_file_size.to_f > 0
                  return  case file_size_unit
                          when 'bytes'
                            max_file_size.to_f
                          when 'kilobytes'
                            max_file_size.to_f * 1024
                          when 'megabytes'
                            (max_file_size.to_f * 1024) * 1024
                          else
                            nil
                          end
                end
              end

            end

            class FileContentTypeValidator < ActiveModel::EachValidator

              def validate_each record, field, value
                attacher = record.send("#{field}_attacher")
                if attacher
                  attacher.errors.each do |err|
                    record.errors.add field, err
                  end
                end
              end

            end

          end
        end
      end
    end
  end
end
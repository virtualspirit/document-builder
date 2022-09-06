
module Document
  module Concerns
    module Models
      module Fields
        module Validations
          module Inclusion

            extend ActiveSupport::Concern

            included do
              embeds_one :inclusion, class_name: "Document::Concerns::Models::Fields::Validations::Inclusion::InclusionOptions"
              accepts_nested_attributes_for :inclusion

              after_initialize do
                build_inclusion unless inclusion
              end
            end

            def interpret_to(model, field_name, accessibility, options = {})
              super
              inclusion&.interpret_to model, field_name, accessibility, options
            end

            class InclusionOptions < Document::FieldOptions
              attribute :message, :string, default: ""
              attribute :in, :string, default: [], array: true

              def interpret_to(model, field_name, _accessibility, _options = {})
                return if self.in.empty?

                options = { in: self.in }
                options[:message] = message if message.present?

                model.validates field_name, inclusion: options, allow_blank: true
              end
            end

          end
        end
      end
    end
  end
end


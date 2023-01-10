module Document
  module Concerns
    module Models
      module Field
        extend ActiveSupport::Concern

        NAME_REGEX = /\A[a-z][a-z_0-9]*\z/.freeze

        included do
          enum accessibility: { read_and_write: 0, readonly: 1, hidden: 2 },
              _prefix: :access

          serialize :validations
          serialize :options

          validates :name,
                    presence: true,
                    uniqueness: { scope: [:section_id, :field_group_id, :form] },
                    exclusion: { in: Document.reserved_names },
                    format: { with: NAME_REGEX }, if: :form_id
          validates :accessibility,
                    inclusion: { in: accessibilities.keys.map(&:to_sym) }

          after_initialize do
            if respond_to? :validations
              self.validations ||= {}
            end
            if respond_to? :options
              self.options ||= {}
            end
            if respond_to? :accessibility
              self.accessibility ||= "read_and_write"
            end
          end

          attr_accessor :skip_options_validation
          attr_accessor :skip_validations_validation

          validate do
            unless skip_options_validation
              unless validations.valid?
                errors.add(:validations, :invalid)
                validations.errors.each {|e| errors.import e, **e.options.merge(attribute: "options.#{e.attribute}")}
              end
            end

            unless skip_options_validation
              unless options.valid?
                errors.add(:options, :invalid)
                options.errors.each {|e| errors.import e, **e.options.merge(attribute: "options.#{e.attribute}")}
              end
            end
          end

        end

        def skip_options_validation!
          self.skip_options_validation = true
        end

        def skip_validations_validation!
          self.skip_validations_validation = true
        end

        def name
          self[:name]&.to_sym
        end

        def accessibility
          self[:accessibility]&.to_sym
        end

        def stored_type
          :text #raise NotImplementedError
        end

        def default_value
          nil
        end

        def has_choices_option?
          false
        end

        def interpret_as_field_for model, overrides: {}
          check_model_validity!(model)

          accessibility = overrides.fetch(:accessibility, self.accessibility)
          return model if accessibility == :hidden

          default_value = overrides.fetch(:default_value, self.default_value)
          model.field name, type: stored_type, default: default_value

          model.add_as_searchable_field self.name if self.options.try(:searchable)

          model
        end

        def interpret_to(model, overrides: {})
          model = interpret_as_field_for model, overrides: overrides
          model.attr_readonly name if accessibility == :readonly

          interpret_validations_to model, accessibility, overrides
          interpret_extra_to model, accessibility, overrides

          model
        end

        protected

          def interpret_validations_to(model, accessibility, overrides = {})
            validations = overrides.fetch(:validations, (self.validations || {}))
            validation_options = overrides.fetch(:validation_options) { self.options.fetch(:validation, {}) }

            model.validates name, **validations, **validation_options if accessibility == :read_and_write && validations.present?
          end

          def interpret_extra_to(_model, _accessibility, _overrides = {}); end

          def check_model_validity!(model)
            unless model.is_a?(Class) && model < ::Document::VirtualModel
              raise ArgumentError, "#{model} must be a #{::Document::VirtualModel}'s subclass"
            end
          end
      end
    end
  end
end

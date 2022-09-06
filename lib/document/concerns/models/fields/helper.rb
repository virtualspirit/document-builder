module Document
  module Concerns
    module Models
      module Fields
        module Helper
          extend ActiveSupport::Concern

          module ClassMethods
            def prepend_features(base)
              if base.instance_variable_defined?(:@_dependencies)
                base.instance_variable_get(:@_dependencies) << self
                false
              else
                return false if base < self

                super
                base.singleton_class.send(:prepend, const_get("ClassMethods")) if const_defined?(:ClassMethods)
                @_dependencies.each { |dep| base.send(:prepend, dep) }
                base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
              end
            end
          end

          def options_configurable?
            options.is_a?(FieldOptions) && (options.attributes.any? || options._reflections.any?)
          end

          def validations_configurable?
            validations.is_a?(FieldOptions) && validations.attributes.any?
          end

          def attached_nested_form?
            false
          end

          def range_field?
            false
          end

          def file_field?
            false
          end

        end
      end
    end
  end
end

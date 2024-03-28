module Document
  module Fields
    module Embeds
      module ActsAsDefaultValue
        extend ActiveSupport::Concern

        class NormalValueContainer
          def initialize(value)
            @value = value
          end

          def evaluate(_instance)
            if @value.duplicable?
              @value.dup
            else
              @value
            end
          end
        end

        class BlockValueContainer
          def initialize(block)
            @block = block
          end

          def evaluate(instance)
            if @block.arity.zero?
              @block.call
            else
              @block.call(instance)
            end
          end
        end

        included do
          after_initialize :set_default_values
        end

        def initialize(attributes = nil)
          @initialization_attributes = attributes.is_a?(Hash) ? attributes.stringify_keys : {}
          super
        end

        def set_default_values
          self.class._all_default_attribute_values.each do |attribute, container|
            next unless new_record? || self.class._all_default_attribute_values_not_allowing_nil.include?(attribute)
            next unless respond_to? attribute

            connection_default_value_defined = new_record? && respond_to?("#{attribute}_changed?") && !send("#{attribute}_changed?")

            #column = self.class.columns.detect { |c| c.name == attribute }
            column = self.class.attribute_types.detect { |c| c[:name] == attribute }
            attribute_blank =
              if column && column[:type].to_s.underscore.to_sym == :boolean
                send(attribute).nil?
              else
                send(attribute).blank?
              end
            next unless connection_default_value_defined || attribute_blank

            # allow explicitly setting nil through allow nil option
            next if @initialization_attributes.is_a?(Hash) &&
                    (
                    @initialization_attributes.key?(attribute) ||
                      (
                      @initialization_attributes.key?("#{attribute}_attributes") &&
                        nested_attributes_options.stringify_keys[attribute]
                    )
                  ) &&
                    !self.class._all_default_attribute_values_not_allowing_nil.include?(attribute)

            send("#{attribute}=", container.evaluate(self))

            remove_change(attribute) if has_attribute?(attribute)
          end
        end

        def attributes_for_create(attribute_names)
          attribute_names += self.class._all_default_attribute_values.keys.map(&:to_s).find_all do |name|
            self.class.fields.map{|f| f[0]}.include?(name.to_s)
          end

          super
        end

        module ClassMethods

          def attribute_types
            fields.reduce([]) { |types, field|
              hash = {}
              hash[:name] = field[1].name.to_sym
              hash[:type] = field[1].type.to_s.underscore.to_sym
              types << hash
              types
            }
          end

          def _default_attribute_values # :nodoc:
            @default_attribute_values ||= {}
          end

          def _default_attribute_values_not_allowing_nil # :nodoc:
            @default_attribute_values_not_allowing_nil ||= Set.new
          end

          def _all_default_attribute_values # :nodoc:
            if superclass.respond_to?(:_default_attribute_values)
              superclass._all_default_attribute_values.merge(_default_attribute_values)
            else
              _default_attribute_values
            end
          end

          def _all_default_attribute_values_not_allowing_nil # :nodoc:
            if superclass.respond_to?(:_default_attribute_values_not_allowing_nil)
              superclass._all_default_attribute_values_not_allowing_nil + _default_attribute_values_not_allowing_nil
            else
              _default_attribute_values_not_allowing_nil
            end
          end

          def default_value_for(attribute, value, **options)
            allow_nil = options.fetch(:allow_nil, true)

            container =
              if value.is_a? Proc
                BlockValueContainer.new(value)
              else
                NormalValueContainer.new(value)
              end

            _default_attribute_values[attribute.to_s] = container
            _default_attribute_values_not_allowing_nil << attribute.to_s unless allow_nil

            attribute
          end
        end
      end
    end
  end
end

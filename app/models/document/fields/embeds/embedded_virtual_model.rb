module Document
  module Fields
    module Embeds
      class EmbeddedVirtualModel

        module Core
          extend ActiveSupport::Concern

          included do

            after_update do
              if name_previously_was != name
                unset_embedded_virtual_model_constant
              end
            end

            after_destroy do
              unset_embedded_virtual_model_constant
            end

          end

          def embedded_virtual_model
            Document::Fields::Embeds::EmbeddedVirtualModel.build(name: embedded_virtual_model_name, type: embedded_virtual_model_type)
          end

          def unset_embedded_virtual_model_constant
            Document::Fields::Embeds::EmbeddedVirtualModel.unset_constant(embedded_virtual_model_name)
          end

          def embedded_virtual_model_name
            "#{name}#{id.to_s.underscore}".classify
          end

          def embedded_virtual_model_type
            arr = self.class.name.demodulize.underscore.split("_")
            arr.pop
            arr.join("_").to_s.to_sym
          end

        end

        # Hack
        ARRAY_WITHOUT_BLANK_PATTERN = "!ruby/array:ArrayWithoutBlank"

        def dump
          self.class.dump(self).gsub(ARRAY_WITHOUT_BLANK_PATTERN, "")
        end

        class << self

          delegate :dump, :load, to: :coder, allow_nil: false

          def coder
            @_coder ||= Document.virtual_model_coder_class.new(self)
          end

          def attr_readonly?(attr_name)
            readonly_attributes.include? attr_name.to_s
          end

          def coder=(klass)
            raise ArgumentError, "#{klass} should be sub-class of #{Coder}." unless klass && klass < Coder

            @_coder = klass.new(self)
          end

          def name
            @_name
          end

          def name=(value)
            value = value.classify
            raise ArgumentError, "`value` isn't a valid class name" if value.blank?

            @_name = value
          end

          def build(name: nil, type: :date_range **opts)
            raise "Name is required" unless name
            if Object.const_defined?(name)
              return name.constantize
            end
            klass = Class.new(self)
            klass.name = name
            klass.include Mongoid::Document
            klass.include ActsAsDefaultValue
            klass.include Document::Concerns::VirtualModels::GeneralSearch
            case type.to_sym
              when :date_range
                klass.include DateRange::Core
              when :datetime_range
                klass.include DatetimeRange::Core
              when :time_range
                klass.include TimeRange::Core
              when :integer_range
                klass.include IntegerRange::Core
              when :decimal_range
                klass.include DecimalRange::Core
              when :geocode
                klass.include Geocode::Core
            end
            set_constant(name, klass)
            klass
          end

          def set_constant klass_name, klass
            unset_constant klass_name if Object.const_defined?(klass_name)
            Object.const_set(klass_name, klass)
          end

          def unset_constant klass_name
            if Object.const_defined?(klass_name)
              Object.send(:remove_const, klass_name)
            end
          end

        end

      end
    end
  end
end
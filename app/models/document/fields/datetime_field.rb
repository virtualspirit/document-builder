module Document
  module Fields
    class DatetimeField < Document::Field

      serialize :validations, coder: Validations::DatetimeField
      serialize :options, coder: Options::DatetimeField

      def stored_type
        :date_time
      end

      protected

        def interpret_extra_to(model, accessibility, overrides = {})
          super

          model.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}=(val)
            super(val.try(:in_time_zone)&.utc)
          end
          CODE
        end

    end
  end
end

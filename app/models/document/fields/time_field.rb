module Document
  module Fields
    class TimeField < Document::Field

      serialize :validations, Validations::TimeField
      serialize :options, Options::TimeField

      def stored_type
        :time
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

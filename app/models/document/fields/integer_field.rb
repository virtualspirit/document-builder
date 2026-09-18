module Document
  module Fields
    class IntegerField < Document::Field

      serialize :validations, coder: Validations::IntegerField
      serialize :options, coder: Options::IntegerField

      def stored_type
        :integer
      end

      protected

        def interpret_extra_to(model, accessibility, _overrides = {})
          return if accessibility != :read_and_write

          model.validates name, numericality: { only_integer: true }, allow_blank: true
        end

    end
  end
end

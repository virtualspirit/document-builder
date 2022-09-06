module Document
  module Fields
    class MultipleSelectField < Document::Field

      serialize :validations, Validations::MultipleSelectField
      serialize :options, Options::MultipleSelectField

      def stored_type
        :string
      end

      def has_choices_option?
        true
      end

      def interpret_to(model, overrides: {})
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        model.field name, type: Array, default: []
        model.attr_readonly name if accessibility == :readonly
        model.add_as_searchable_field name if options.try(:searchable)

        interpret_validations_to model, accessibility, overrides
        interpret_extra_to model, accessibility, overrides

        model
      end

      protected

        def interpret_extra_to(model, accessibility, overrides = {})
          super
          return if accessibility != :read_and_write || !options.strict
          model.validates_with Document::Concerns::Models::Fields::Validators::SubsetValidator, _merge_attributes([name, in: options.choices.pluck(:value) , allow_blank: true])
        end

    end
  end
end

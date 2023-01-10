module Document
  module Fields
    class IntegerRangeField < Document::Field

      serialize :validations, Validations::IntegerRangeField
      serialize :options, Options::IntegerRangeField

      def interpret_as_field_for(model, overrides: {})
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        nested_model = Document::Fields::Embeds::IntegerRange

        model.nested_models[name] = nested_model

        model.embeds_one name, class_name: nested_model.name, validate: true
        model.accepts_nested_attributes_for name, reject_if: :all_blank
        model.add_as_searchable_field name if options.try(:searchable)
        model
      end

      # def interpret_to(model, overrides: {})

      #   interpret_validations_to model, accessibility, overrides
      #   interpret_extra_to model, accessibility, overrides

      #   model
      # end

      def range_field?
        true
      end

    end
  end
end

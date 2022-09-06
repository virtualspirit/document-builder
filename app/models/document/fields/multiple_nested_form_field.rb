module Document
  module Fields
    class MultipleNestedFormField < Document::Field

      after_create do
        build_nested_form.save! unless nested_form.present?
      end

      serialize :validations, Validations::MultipleNestedFormField
      serialize :options, Document::NonConfigurableField

      def attached_nested_form?
        true
      end

      def interpret_to(model, overrides: {})
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        overrides[:name] = name

        nested_model = nested_form.to_virtual_model(overrides: { _global: { accessibility: accessibility } })

        model.nested_models[name] = nested_model

        model.embeds_many name, class_name: nested_model.name, validate: true
        nested_model.embedded_in model.name.downcase.to_sym, class_name: model.name
        model.accepts_nested_attributes_for name, reject_if: :all_blank, allow_destroy: true
        model.attr_readonly name if accessibility == :readonly

        interpret_validations_to model, accessibility, overrides
        interpret_extra_to model, accessibility, overrides

        model
      end

    end
  end
end

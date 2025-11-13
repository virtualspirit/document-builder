module Document
  module Fields
    class DepedencyOneField < Document::Field

      serialize :validations, Validations::DepedencyOneField
      serialize :options, Options::DepedencyField

      def stored_type
        :string
      end

      def interpret_as_field_for model, overrides: {}
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        overrides[:name] = name
        reference_class_id = options.document_form_id
        if model.form_id == reference_class_id
          reference_class = model
        else
          reference_class = options.virtual_model
        end
        if reference_class
          model.field "#{name}_id", type: BSON::ObjectId
          model.belongs_to name, class_name: reference_class.name, validate: false, autosave: false, optional: true
          reference_class.has_one model.name.downcase.to_sym, class_name: model.name, validate: false, autosave: false
          model.attr_readonly name if accessibility == :readonly

          interpret_validations_to model, accessibility, overrides
          interpret_extra_to model, accessibility, overrides
        end
        model

      end

      def interpret_to(model, overrides: {})
        interpret_as_field_for model, overrides: overrides
      end

    end
  end
end

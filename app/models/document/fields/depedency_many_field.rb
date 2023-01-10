module Document
  module Fields
    class DepedencyManyField < Document::Field

      serialize :validations, Validations::DepedencyManyField
      serialize :options, Options::DepedencyField

      def stored_type
        :array
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
          model.field "#{name}_ids", type: Array, default: []
          model.has_and_belongs_to_many name, class_name: reference_class.name
          # reference_class.has_and_belongs_to_many model.name.downcase.to_sym, class_name: model.name
          model.attr_readonly name if accessibility == :readonly
          interpret_validations_to model, accessibility, overrides
          interpret_extra_to model, accessibility, overrides
        end
        model
      end

      def interpret_to(model, overrides: {})
        model = interpret_as_field_for model, overrides: overrides
        model
      end

    end
  end
end

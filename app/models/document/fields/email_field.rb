module Document
  module Fields
    class EmailField < Document::Field

      serialize :validations, Validations::EmailField
      serialize :options, Options::EmailField

      def stored_type
        :string
      end

      def interpret_as_field_for(model, overrides: {})
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        if options.multiple
          model.field name, type: Array, default: []
        else
          model.field name, type: stored_type
        end
        model.attr_readonly name if accessibility == :readonly

        model.add_as_searchable_field name if options.try(:searchable)
        model
      end

      # def interpret_to(model, overrides: {})

      #   interpret_validations_to model, accessibility, overrides
      #   interpret_extra_to model, accessibility, overrides

      #   model
      # end

    end
  end
end

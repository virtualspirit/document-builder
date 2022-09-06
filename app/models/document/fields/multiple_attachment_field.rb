module Document
  module Fields
    class MultipleAttachmentField < Document::Field

      serialize :validations, Validations::MultipleAttachmentField
      serialize :options, Options::MultipleAttachmentField

      def stored_type
        :string
      end

      ## TODO
      def interpret_to(model, overrides: {})
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        nested_model = Document::Fields::Embeds::MultipleAttachment

        model.nested_models[name] = nested_model
        model.embeds_many name, class_name: nested_model.name
        model.accepts_nested_attributes_for name, reject_if: :all_blank, allow_destroy: true
        model.has_many_attached name

        model.attr_readonly name if accessibility == :readonly

        interpret_validations_to model, accessibility, overrides
        interpret_extra_to model, accessibility, overrides

        model
      end

      def interpret_validations_to model, accessibility, overrides
        file_validation = self.options
        model.relations[name].klass.uploadable_validations(fieldname: :attachment, validations: {max_file_size: file_validation.max_file_size_in_bytes, whitelist: file_validation.whitelist})
        super(model, accessibility, overrides)
      end

      def file_field?
        true
      end

    end
  end
end

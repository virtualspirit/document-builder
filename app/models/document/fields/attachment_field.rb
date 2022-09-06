# frozen_string_literal: true
module Document
  module Fields
    class AttachmentField < Field
      serialize :validations, Validations::AttachmentField
      serialize :options, Options::AttachmentField

      def stored_type
        :string
      end

      def interpret_to(model, overrides: {})
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden
        model.has_one_attached name
        model.attr_readonly name if accessibility == :readonly

        interpret_validations_to model, accessibility, overrides
        interpret_extra_to model, accessibility, overrides

        model
      end

      def interpret_validations_to model, accessibility, overrides
        file_validation = self.validations.file
        model.uploadable_validations(fieldname: name.to_sym, validations: {presence: validations.presence, max_file_size: validations.file.max_file_size_in_bytes, whitelist: validations.file.whitelist})
        super(model, accessibility, overrides)
      end

      def file_field?
        true
      end

    end
  end
end

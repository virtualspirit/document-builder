module Document
  module Fields
    class DepedencyFieldPresenter < FieldPresenter

      def initialize(model, section, options = {})
        super(model)

        @model = model
        @section = section
        @options = options
        @options.append_choices_as_json
      end

      def value_for_preview
        virtual_model.find(value)
      end

      def virtual_model
        @virtual_model ||= @model.options.virtual_model
      end

      def choices
        @choices ||= @model.options.choices
      end

    end
  end
end

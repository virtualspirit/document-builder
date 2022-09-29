module Document
  module Fields
    class DepedencyOneFieldPresenter < FieldPresenter

      def value_for_preview
        att = @model.options.display_value_field
        virtual_model.find(value).try(att)
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
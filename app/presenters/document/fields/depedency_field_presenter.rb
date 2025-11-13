module Document
  module Fields
    class DepedencyFieldPresenter < FieldPresenter

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

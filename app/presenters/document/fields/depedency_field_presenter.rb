module Document
  module Fields
    class DepedencyFieldPresenter < FieldPresenter

      def value_for_preview
        virtual_model.find(value)
      end

      def form
        @model.options.form
      end

      def virtual_model
        @model.options.virtual_model
      end

    end
  end
end

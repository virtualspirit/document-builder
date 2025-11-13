module Document
  module Fields
    class RadioFieldPresenter < FieldPresenter

      def value_for_preview
        super
      end

      def choices
        @model.options.choices
      end

    end
  end
end

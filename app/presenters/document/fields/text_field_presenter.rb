module Document
  module Fields
    class TextFieldPresenter < FieldPresenter

      def multiline
        @model.options.multiline
      end
      alias multiline? multiline

    end
  end
end

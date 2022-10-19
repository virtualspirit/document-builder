module Document
  module Fields
    class EmailFieldPresenter < FieldPresenter

      def multiple
        @model.options.multiple
      end

      alias multiple? multiple

    end
  end
end

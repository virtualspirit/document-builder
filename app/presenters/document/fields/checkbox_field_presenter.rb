module Document
  module Fields
    class CheckboxFieldPresenter < FieldPresenter

      def value_for_preview
        super.join(", ")
      end

    end
  end
end

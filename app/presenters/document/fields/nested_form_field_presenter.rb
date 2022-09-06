module Document
  module Fields
    class NestedFormFieldPresenter < CompositeFieldPresenter

      def nested_form_field?
        true
      end

    end
  end
end
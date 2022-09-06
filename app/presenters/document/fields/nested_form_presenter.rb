module Document
  module Fields
    class NestedFormPresenter < CompositeFieldPresenter

      def nested_form_field?
        true
      end

    end
  end
end

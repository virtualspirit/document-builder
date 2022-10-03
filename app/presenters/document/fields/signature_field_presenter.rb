module Document
  module Fields
    class SignatureFieldPresenter < FieldPresenter

      def value_for_preview
        "<img src='#{super}' />".html_safe
      end

    end
  end
end

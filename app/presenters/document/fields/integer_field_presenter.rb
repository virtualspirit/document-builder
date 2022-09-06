module Document
  module Fields
    class IntegerFieldPresenter < FieldPresenter

      include Document::Concerns::Fields::PresenterForNumberField

      def integer_only?
        true
      end

    end
  end
end

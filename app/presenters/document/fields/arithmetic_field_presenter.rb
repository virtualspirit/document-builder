module Document
  module Fields
    class ArithmeticFieldPresenter < FieldPresenter

      include Document::Concerns::Fields::PresenterForCalculatedField

    end
  end
end

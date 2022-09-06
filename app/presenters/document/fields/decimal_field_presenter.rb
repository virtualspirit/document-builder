module Document
  module Fields
    class DecimalFieldPresenter < FieldPresenter

      include Document::Concerns::Fields::PresenterForNumberField

    end
  end
end

module Document
  module Fields
    class BooleanFieldPresenter < FieldPresenter

      def required
        @model.validations&.acceptance
      end

      def value_for_preview
        super ? I18n.t("values.true") : I18n.t("values.false")
      end

    end
  end
end

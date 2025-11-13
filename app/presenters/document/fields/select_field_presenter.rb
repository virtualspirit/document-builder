module Document
  module Fields
    class SelectFieldPresenter < FieldPresenter

      def include_blank?
        required?
      end

      def can_custom_value?
        !@model.options.strict
      end

      def collection
        collection = @model.options.choices
        if can_custom_value? && value.present?
          ([value] + collection).uniq
        else
          collection
        end
      end

    end
  end
end

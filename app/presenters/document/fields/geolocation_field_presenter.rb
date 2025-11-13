module Document
  module Fields
    class GeolocationFieldPresenter < FieldPresenter

      def value_for_preview
        target&.read_attribute(location_field_suffix_name)
      end

      def fill_method
        @model.options.fill_method
      end

      def location_field_suffix_name
        @model.options.location_field_suffix_name
      end

      def location_field_suffix_name
        "#{@model.id}#{@model.options.location_field_suffix_name}"
      end

    end
  end
end

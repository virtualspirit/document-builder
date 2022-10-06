module Document
  module Fields::Options
    class GeolocationField < BaseOptions

      attribute :fill_method, :string, default: "automatic"
      attribute :location_field_suffix_name, :string, default: "_location"

      validates :fill_method,
                presence: true,
                inclusion: { in: ['automatic', 'automatic_with_location', 'manual'], allow_blank: true }

    end
  end
end

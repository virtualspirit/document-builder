module Document
  module Fields::Embeds
    class Geocode < Base

      module Core
        extend ActiveSupport::Concern

        included do

          field :coordinates, type: Array
          field :location, type: String

          index({ coordinates: "2d" }, { min: -180, max: 180 })

          validates :location,
                    presence: true

          validates :coordinates,
                    presence: true,
                    length: {is: 2, allow_blank: true},
                    if: -> { read_attribute(:location).present? }

          before_save :update_coordinates, if: :coordinates_changed?

        end

        def update_coordinates
          self.coordinates = (self.coordinates || []).map(&:to_f)
        end

      end

      include Core

    end
  end
end

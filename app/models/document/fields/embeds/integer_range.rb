module Document
  module Fields::Embeds
    class IntegerRange < Base

      module Core
        extend ActiveSupport::Concern

        included do
          field :begin, type: :big_decimal
          field :end, type: :big_decimal
          validates :begin, :end,
                    presence: true,
                    numericality: { only_integer: true }

          validates :end,
                    numericality: {
                      greater_than: :begin
                    },
                    allow_blank: true,
                    if: -> { read_attribute(:begin).present? }
        end

      end

      include Core

    end
  end
end

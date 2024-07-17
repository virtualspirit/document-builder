module Document
  module Fields::Embeds
    class IntegerRange < Base

      field :from, type: :big_decimal
      field :to, type: :big_decimal

      validates :from, :to,
                presence: true,
                numericality: { only_integer: true }

      validates :to,
                numericality: {
                  greater_than: :from
                },
                allow_blank: true,
                if: -> { read_attribute(:from).present? }

    end
  end
end

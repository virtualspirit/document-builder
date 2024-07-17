module Document
  module Fields::Embeds
    class DecimalRange < Base

      field :from, type: :big_decimal
      field :to, type: :big_decimal

      validates :from, :to,
                presence: true,
                numericality: { only_integer: false }

      validates :to,
                numericality: {
                  greater_than: :from
                },
                allow_blank: true,
                if: -> { read_attribute(:from).present? }

      def begin
        from
      end

      def end
        to
      end

    end
  end
end

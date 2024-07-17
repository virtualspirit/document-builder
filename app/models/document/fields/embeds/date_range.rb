module Document
  module Fields::Embeds
    class DateRange < Base

      field :from, type: :date_time
      field :to, type: :date_time

      validates :from,
                presence: true

      validates :to,
                timeliness: {
                  after: :from,
                  type: :date
                },
                allow_blank: true,
                if: -> { read_attribute(:from).present? }

      def from=(val)
        super(val.try(:in_time_zone)&.utc)
      end

      def to=(val)
        super(val.try(:in_time_zone)&.utc)
      end

      def from
        super.try(:in_time_zone)&.utc
      end

      def to
        super.try(:in_time_zone)&.utc
      end

      def begin
        from
      end

      def end
        to
      end

    end
  end
end

module Document
  module Fields::Embeds
    class DatetimeRange

      include Mongoid::Document

      field :begin, type: :date_time
      field :end, type: :date_time

      validates :begin,
                presence: true

      validates :end,
                timeliness: {
                  after: :begin,
                  type: :datetime
                },
                allow_blank: true,
                if: -> { read_attribute(:begin).present? }

      def begin=(val)
        super(val.try(:in_time_zone)&.utc)
      end

      def end=(val)
        super(val.try(:in_time_zone)&.utc)
      end

    end
  end
end

module Document
  module Fields::Embeds
    class TimeRange

      include Mongoid::Document

      field :begin, type: :time
      field :end, type: :time

      validates :begin,
                presence: true

      validates :end,
                timeliness: {
                  after: :begin,
                  type: :time
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

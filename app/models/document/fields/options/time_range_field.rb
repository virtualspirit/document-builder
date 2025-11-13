module Document
  module Fields::Options
    class TimeRangeField < BaseOptions

      attribute :format, :string, default: "24"
      attribute :begin_from, :string, default: "unlimited"
      enum begin_from: {
        unlimited: "unlimited",
        now: "now",
        time: "time",
        minutes_before_end: "minutes_before_end"
      }, _prefix: :begin_from

      attribute :begin, :time
      attribute :fixed_begin, :boolean, default: false
      attribute :begin_from_now_minutes_offset, :integer, default: 0
      attribute :minutes_before_end, :integer, default: 1

      attribute :end_to, :string, default: "unlimited"
      enum end_to: {
        unlimited: "unlimited",
        now: "now",
        time: "time",
        minutes_since_begin: "minutes_since_begin"
      }, _prefix: :end_to

      attribute :end, :time
      attribute :fixed_end, :boolean, default: false
      attribute :nullable_end, :boolean, default: false
      attribute :end_to_now_minutes_offset, :integer, default: 0
      attribute :minutes_since_begin, :integer, default: 1

      attribute :minimum_distance, :integer, default: 0
      attribute :maximum_distance, :integer, default: 0

      validates :format, inclusion: { in: ["24", "AM/PM", "am/pm"] }
      validates :begin_from, :end_to,
                presence: true

      validates :begin,
                presence: true,
                if: :begin_from_time?

      validates :end,
                presence: true,
                if: :end_to_time?

      validates :minutes_before_end,
                numericality: {
                  only_integer: true,
                  greater_than: 0
                },
                allow_blank: false,
                if: :begin_from_minutes_before_end?

      validates :minutes_since_begin,
                numericality: {
                  only_integer: true,
                  greater_than: 0
                },
                allow_blank: false,
                if: :end_to_minutes_since_begin?

      validates :begin_from_now_minutes_offset, :end_to_now_minutes_offset,
                presence: true,
                numericality: {
                  only_integer: true
                }

      validates :begin,
                timeliness: {
                  before: ->(r) { (Time.zone.now.change(sec: 0, usec: 0) + r.end_to_now_minutes_offset.minutes).strftime(r.time_format) },
                  type: :time
                },
                allow_blank: false,
                if: %i[begin_from_time? end_to_now?]

      validates :end,
                timeliness: {
                  after: -> { (Time.zone.now.change(sec: 0, usec: 0) + r.begin_from_now_minutes_offset.minutes).strftime(r.time_format) },
                  type: :time
                },
                allow_blank: false,
                if: %i[begin_from_now? end_to_time?]

      validates :end,
                timeliness: {
                  after: -> (r) { r.begin.strftime(r.time_format) },
                  type: :time
                },
                allow_blank: false,
                if: %i[begin_from_time? end_to_time?]

      validates :end_to,
                exclusion: { in: %w[now] },
                if: [:begin_from_now?]

      validates :end_to,
                exclusion: { in: %w[minutes_since_begin] },
                if: [:begin_from_minutes_before_end?]

      validates :fixed_end,
                absence: true,
                if: [:fixed_begin]

      validates :fixed_begin,
                absence: true,
                if: ->(r) { r.begin_from_minutes_before_end? || r.begin_from_unlimited? }

      validates :fixed_end,
                absence: true,
                if: ->(r) { r.end_to_minutes_since_begin? || r.end_to_unlimited? }

      validates :minimum_distance,
                numericality: {
                  only_integer: true,
                  greater_than_or_equal_to: 0
                },
                allow_blank: false

      validates :maximum_distance,
                numericality: {
                  only_integer: true,
                  greater_than_or_equal_to: :minimum_distance
                },
                allow_blank: false,
                unless: ->(r) { r.maximum_distance.to_i.zero? }

      def interpret_to(model, field_name, accessibility, _options = {})
        return unless accessibility == :read_and_write

        klass = model.nested_models[field_name]

        unless nullable_end
          klass.validates :to,
                          presence: true
        end

        if begin_from_now?
          begin_minutes_offset = begin_from_now_minutes_offset.minutes.to_i
          klass.validates :from,
                          timeliness: {
                            on_or_after: -> { (Time.zone.now.change(sec: 0, usec: 0) + begin_minutes_offset).strftime(time_format) },
                            type: :time
                          },
                          allow_blank: true
          klass.default_value_for :from,
                                  ->(_) { (Time.zone.now.change(sec: 0, usec: 0) + begin_minutes_offset).strftime(time_format) },
                                  allow_nil: false
          klass.attr_readonly :from if fixed_begin
        elsif begin_from_time?
          klass.validates :from,
                          timeliness: {
                            on_or_after: self.begin.strftime(time_format),
                            type: :time
                          },
                          allow_blank: true
          klass.default_value_for :from,
                                  self.begin,
                                  allow_nil: false
          klass.attr_readonly :from if fixed_begin
        elsif begin_from_minutes_before_end?
          minutes_before_end = self.minutes_before_end.minutes.to_i
          klass.validates :from,
                          timeliness: {
                            on_or_after: ->(r) { (r.to - minutes_before_end).strftime(time_format) },
                            type: :time
                          },
                          allow_blank: true
        end

        if end_to_now?
          end_minutes_offset = end_to_now_minutes_offset.minutes.to_i

          klass.validates :to,
                          timeliness: {
                            on_or_before: -> { (Time.zone.now.change(sec: 0, usec: 0) + end_minutes_offset).strftime(time_format) },
                            type: :time
                          },
                          allow_blank: true
          klass.default_value_for :to,
                                  ->(_) { (Time.zone.now.change(sec: 0, usec: 0) + end_minutes_offset).strftime(time_format) },
                                  allow_nil: false
          klass.attr_readonly :to if fixed_end
        elsif end_to_time?
          klass.validates :to,
                          timeliness: {
                            on_or_before: self.end.strftime(time_format),
                            type: :time
                          },
                          allow_blank: true
          klass.default_value_for :to,
                                  self.end,
                                  allow_nil: false
          klass.attr_readonly :to if fixed_end
        elsif end_to_minutes_since_begin?
          minutes_since_begin = self.minutes_since_begin.minutes.to_i
          klass.validates :to,
                          timeliness: {
                            on_or_before: ->(r) { (r.from + minutes_since_begin).strftime(time_format) },
                            type: :time
                          },
                          allow_blank: true
        end

        if minimum_distance.positive?
          minimum_distance_minutes = minimum_distance.minutes
          if fixed_begin || begin_from_now? || begin_from_time? || end_to_minutes_since_begin?
            klass.validates :to,
                            timeliness: {
                              on_or_after: ->(r) { (r.from + minimum_distance_minutes).strftime(time_format) },
                              type: :time
                            },
                            allow_blank: false,
                            if: -> { read_attribute(:from).present? }
          elsif fixed_end || end_to_now? || end_to_time? || begin_from_minutes_before_end?
            klass.validates :from,
                            timeliness: {
                              on_or_before: ->(r) { (r.to - minimum_distance_minutes).strftime(time_format) },
                              type: :time
                            },
                            allow_blank: false,
                            if: -> { read_attribute(:to).present? }
          else
            klass.validates :to,
                            timeliness: {
                              on_or_after: ->(r) { (r.from + minimum_distance_minutes).strftime(time_format) },
                              type: :time
                            },
                            allow_blank: false,
                            if: -> { read_attribute(:from).present? }
          end
        end

        if maximum_distance.positive?
          maximum_distance_minutes = maximum_distance.minutes
          if fixed_begin || begin_from_now? || begin_from_time? || end_to_minutes_since_begin?
            klass.validates :to,
                            timeliness: {
                              on_or_before: ->(r) { (r.from + maximum_distance_minutes).strftime(time_format) },
                              type: :time
                            },
                            allow_blank: false,
                            if: -> { read_attribute(:from).present? }
          elsif fixed_end || end_to_now? || end_to_time? || begin_from_minutes_before_end?
            klass.validates :to,
                            timeliness: {
                              on_or_after: ->(r) { (r.to - maximum_distance_minutes).strftime(time_format) },
                              type: :time
                            },
                            allow_blank: false,
                            if: -> { read_attribute(:to).present? }
          else
            klass.validates :end,
                            timeliness: {
                              on_or_before: ->(r) { (r.from + maximum_distance_minutes).strftime(time_format) },
                              type: :time
                            },
                            allow_blank: false,
                            if: -> { read_attribute(:from).present? }
          end
        end
      end

      def time_format
        if attributes['format'] == '24'
          "%k:%M"
        else
          "%l:%M%P"
        end
      end

    end
  end
end

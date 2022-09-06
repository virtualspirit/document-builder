module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class DatetimeRangeField < Document::Grape::Presenters::Fields::Option
            expose :begin_from
            expose :begin
            expose :fixed_begin
            expose :begin_from_now_minutes_offset
            expose :minutes_before_end
            expose :end_to
            expose :end
            expose :fixed_end
            expose :nullable_end
            expose :end_to_now_minutes_offset
            expose :minutes_since_begin
            expose :minimum_distance
            expose :maximum_distance
          end
        end
      end
    end
  end
end
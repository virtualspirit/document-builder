module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class DatetimeField < Document::Grape::Presenters::Fields::Option
            expose :begin_from
            expose :begin
            expose :begin_from_now_minutes_offset
            expose :minutes_before_end
            expose :end_to
            expose :end
            expose :end_to_now_minutes_offset
            expose :minutes_since_begin
          end
        end
      end
    end
  end
end
module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class DateField < Document::Grape::Presenters::Fields::Option
            expose :begin_from
            expose :begin
            expose :begin_from_today_days_offset
            expose :days_before_end
            expose :end_to
            expose :end
            expose :end_to_today_days_offset
            expose :days_since_begin
          end
        end
      end
    end
  end
end
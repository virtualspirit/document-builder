module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class IntegerRangeField < Document::Grape::Presenters::Fields::Option
            expose :begin_from
            expose :begin_value
            expose :fixed_begin
            expose :offsets_before_end
            expose :end_to
            expose :end_value
            expose :fixed_end
            expose :offsets_since_begin
            expose :minimum_gap_check
            expose :maximum_gap_check
            expose :minimum_gap_value
            expose :maximum_gap_value
          end
        end
      end
    end
  end
end

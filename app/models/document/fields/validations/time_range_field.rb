module Document
  module Fields
    module Validations
      class TimeRangeField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
      end
    end
  end
end

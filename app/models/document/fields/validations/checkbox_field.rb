module Document
  module Fields
    module Validations
      class CheckboxField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
        include Document::Concerns::Models::Fields::Validations::Length
      end
    end
  end
end

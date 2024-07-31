module Document
  module Fields
    module Validations
      class BooleanField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Acceptance
        include Document::Concerns::Models::Fields::Validations::Presence
      end
    end
  end
end

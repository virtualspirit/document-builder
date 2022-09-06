module Document
  module Fields
    module Validations
      class BooleanField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Acceptance
      end
    end
  end
end

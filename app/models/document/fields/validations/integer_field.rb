module Document
  module Fields
    module Validations
      class IntegerField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
        include Document::Concerns::Models::Fields::Validations::Numericality
      end
    end
  end
end

module Document
  module Fields
    module Validations
      class DepedencyManyField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
        include Document::Concerns::Models::Fields::Validations::Length
      end
    end
  end
end

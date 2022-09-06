module Document
  module Fields
    module Validations
      class TextField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
        include Document::Concerns::Models::Fields::Validations::Length
        include Document::Concerns::Models::Fields::Validations::Format
      end
    end
  end
end

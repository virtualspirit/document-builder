module Document
  module Fields
    module Validations
      class EmailField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
        include Document::Concerns::Models::Fields::Validations::Email
      end
    end
  end
end

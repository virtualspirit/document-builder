module Document
  module Fields
    module Validations
      class RadioField < Document::FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
      end
    end
  end
end

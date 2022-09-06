module Document
  module Fields
    module Validations
      class MultipleAttachmentField < FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
        include Document::Concerns::Models::Fields::Validations::Length
      end
    end
  end
end

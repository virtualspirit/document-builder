module Document
  module Fields
    module Validations
      class AttachmentField < FieldOptions
        include Document::Concerns::Models::Fields::Validations::Presence
        include Document::Concerns::Models::Fields::Validations::File
      end
    end
  end
end

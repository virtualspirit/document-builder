module Document
  class FieldGroup < ApplicationRecord

    self.table_name = "document_field_groups"

    has_many :fields, class_name: "Document::Field", inverse_of: :field_group, dependent: :destroy
    accepts_nested_attributes_for :fields, allow_destroy: true

  end
end
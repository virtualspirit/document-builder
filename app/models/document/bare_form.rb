module Document
  class BareForm < ApplicationRecord
    include Document::Concerns::Models::Form

    self.table_name = "document_forms"

    has_many :fields, -> { rank(:position) }, class_name: "Document::Field", dependent: :destroy, foreign_key: "form_id", inverse_of: :form
    accepts_nested_attributes_for :fields, allow_destroy: true
    alias_method :inputs=, :fields_attributes=

  end
end

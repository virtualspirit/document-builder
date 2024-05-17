module Document
  class BareForm < ApplicationRecord
    include Document::Concerns::Models::Form

    self.table_name = "document_forms"

    include Document::Concerns::Models::ActsAsGridViewable

    has_many :sections, -> { rank(:position) }, class_name: "Document::Section", dependent: :destroy, inverse_of: :form, index_errors: true, foreign_key: "form_id"
    has_many :fields, -> { rank(:position_on_form) }, class_name: "Document::Field", dependent: :destroy, foreign_key: "form_id", inverse_of: :form, index_errors: true
    accepts_nested_attributes_for :fields, allow_destroy: true
    alias_method :inputs=, :fields_attributes=

  end
end

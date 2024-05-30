module Document
  class BareForm < ApplicationRecord
    include Document::Concerns::Models::Form

    self.table_name = "document_forms"

    include Document::Concerns::Models::ActsAsGridViewable

    #belongs_to :attachable, polymorphic: true, touch: true, inverse_of: :nested_form, optional: true
    #belongs_to :attachable, class_name: 'Document::Field', touch: true, optional: true, foreign_key: "attachable_id"
    # has_many :sections, -> { rank(:position) }, class_name: "Document::Section", dependent: :destroy, inverse_of: :form, index_errors: true, foreign_key: "form_id"
    # has_many :fields, -> { rank(:position_on_form) }, class_name: "Document::Field", dependent: :destroy, foreign_key: "form_id", inverse_of: :form, index_errors: true
    has_many :fields, -> { rank(:position_on_form) }, class_name: Fbuilder.config.document.field_model_class, dependent: :destroy, counter_cache: :fields_count, index_errors: true, foreign_key: "form_id", inverse_of: :form

    accepts_nested_attributes_for :fields, allow_destroy: true
    alias_method :inputs=, :fields_attributes=

    # include ::IdentityCache
    # cache_has_many :sections, embed: true
    # cache_has_many :fields, embed: true
    # cache_belongs_to :attachable

  end
end

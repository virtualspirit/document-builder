module Document
  class BareForm < ApplicationRecord
    include Document::Concerns::Models::Form

    self.table_name = "document_forms"

    include Document::Concerns::Models::ActsAsGridViewable

    belongs_to :attachable, polymorphic: true, touch: true, inverse_of: :nested_form, optional: true
    has_many :sections, -> { rank(:position) }, class_name: "Document::Section", dependent: :destroy, inverse_of: :form, index_errors: true, foreign_key: "form_id"
    has_many :fields, -> { rank(:position_on_form) }, class_name: "Document::Field", dependent: :destroy, foreign_key: "form_id", inverse_of: :form, index_errors: true
    accepts_nested_attributes_for :fields, allow_destroy: true
    alias_method :inputs=, :fields_attributes=

    # include ::IdentityCache
    # cache_has_many :sections, embed: true
    # cache_has_many :fields, embed: true
    # cache_belongs_to :attachable

    cache_this :cached_fields do
      value do |form|
        form.fields.all.map(&:reload)
      end
      invalidate_when [:after_commit]
      before_invalidate do |form|
        form.cached_fields.each(&:invalidate_cache_of_cached_form)
      end
    end

    cache_this :cached_sections do
      value do |form|
        form.sections.all.map(&:reload)
      end
      invalidate_when [:after_commit]
      before_invalidate do |form|
        form.cached_sections.each(&:invalidate_cache_of_cached_form)
      end
    end

  end
end

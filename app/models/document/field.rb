module Document
  class Field < ApplicationRecord
    include Document::Concerns::Models::Field
    include Document::Concerns::Models::Fields::Helper
    include Document::Concerns::Models::ActsAsGridField

    serialize :validations, ::Document::FieldOptions
    serialize :options, ::Document::FieldOptions

    self.table_name = "document_fields"

    belongs_to :form, class_name: 'Document::BareForm', touch: true, optional: true, inverse_of: :fields, counter_cache: true
    belongs_to :section, class_name: Document.section_model_class, touch: true, optional: true, inverse_of: :fields, counter_cache: true
    #has_one :nested_form, class_name: 'Document::BareForm', as: :attachable, dependent: :destroy, inverse_of: :attachable
    has_one :nested_form, class_name: 'Document::NestedForm', dependent: :destroy, inverse_of: :attachable, foreign_key: "attachable_id"
    accepts_nested_attributes_for :nested_form, allow_destroy: true
    belongs_to :field_group, class_name: "Document::FieldGroup", touch: true, optional: true, inverse_of: :fields

    include Document::Concerns::Models::Cachers::Field
    # include ::IdentityCache
    # cache_belongs_to :form
    # cache_belongs_to :section
    # cache_has_one :nested_form, embed: :id

    scope :only_belongs_to_section, -> { where.not(section_id: nil) }
    scope :only_not_belongs_to_section, -> { where(section_id: nil) }

    before_validation do
      if form_id.blank?
        if section
          self.form_id= section.form_id
        end
      end
      self.data_type = stored_type
    end

    include RankedModel
    #ranks :position, with_same: [:form_id], class_name: self.name
    ranks :position_on_section, with_same: [:section_id], class_name: self.name, scope: :only_belongs_to_section
    ranks :position_on_form, with_same: [:form_id], class_name: self.name

    attr_accessor :set_position_on_form
    attr_accessor :set_position_on_section

    def set_position_on_form=(value)
      @set_position_on_form=value
      self.position_on_form_position= value
    end

    def set_position_on_section=(value)
      @set_position_on_section= value
      self.position_on_section_position= value
    end

    after_validation do
      if position_on_section.nil? && section_id.present?
        set_position_on_section= :last
      end
      if position_on_form.nil? && section_id.blank?
        set_position_on_form= :last
      end
    end

    before_create do
      if position_on_form.blank? || position_on_form_position.blank?
        self.position_on_form= form.fields[-1].try(:position_on_form).to_i + 1
      end
    end

    after_commit do
      if section_id && saved_change_to_position_on_section?
        # overral_pos = form.sections.rank(:position).reduce(0) do |sum, s|
        #   if s.id != section_id
        #     sum + s.fields_count.to_i
        #   else
        #     break sum + position_on_section_rank
        #   end
        # end
        #update(set_position_on_form: section.position_rank * section.fields_count  + self.position_on_section_rank)
      end
    end

    validates :form,
              presence: true,
              if: Proc.new {|field| field.field_group.blank? && field.nested_form.blank?  }

    validates :label,
            presence: true
    validates :type,
              inclusion: {
                in: ->(_) { Field.descendants.map(&:to_s) }
              },
              allow_blank: false
    validates :section_id, absence: true, if: proc{|f|
      f.form && f.form.type == 'Document::NestedForm'
    }
    validates :set_position_on_section, absence: true, unless: proc { section_id || section }
    validates :set_position_on_form, absence: true, if: proc { section_id || section }
    validate do
      if persisted?
        errors.add(:name, :invalid) if name_in_database.to_s != name.to_s
      end
    end

    default_value_for :name,
                      ->(_) { "field_#{SecureRandom.hex(3)}" },
                      allow_nil: false

    def self.type_key
      model_name.name.demodulize.underscore.to_sym
    end

    def type_key
      self.class.type_key
    end

    protected

      def interpret_validations_to(model, accessibility, overrides = {})
        return unless accessibility == :read_and_write

        validations_overrides = overrides.fetch(:validations) { {} }
        validations =
          if validations_overrides.any?
            self.validations.dup.update(validations_overrides)
          else
            self.validations
          end

        validations.interpret_to(model, name, accessibility)
      end

      def interpret_extra_to(model, accessibility, overrides = {})
        options_overrides = overrides.fetch(:options) { {} }
        options =
          if options_overrides.any?
            self.options.dup.update(options_overrides)
          else
            self.options
          end
        options.interpret_to(model, name, accessibility)
      end

  end
end

require_dependency "document/fields"
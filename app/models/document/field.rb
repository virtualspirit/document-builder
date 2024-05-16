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
    has_one :nested_form, as: :attachable, dependent: :destroy, inverse_of: :attachable
    accepts_nested_attributes_for :nested_form, allow_destroy: true
    belongs_to :field_group, class_name: "Document::FieldGroup", touch: true, optional: true, inverse_of: :fields

    scope :only_belongs_to_section, -> { where.not(section_id: nil) }
    scope :only_not_belongs_to_section, -> { where(section_id: nil) }

    before_validation do
      if form_id.blank?
        if section
          self.form = section.form
        end
      end
      self.data_type = stored_type
    end

    def set_as_default
      update(default: true)
    end

    include RankedModel
    ranks :position, with_same: [:form_id], class_name: self.name
    ranks :section_order, with_same: [:section_id], class_name: self.name, scope: :only_belongs_to_section

    def reindex_order!
      self.reindex_order= true
    end

    before_validation do
      self.section_order ||= 1
      self.position ||= 1
    end

    attr_accessor :reindex_order

    after_validation if: :reindex_order do
      if position_was != position && !position.nil?
        if section_id
          self.section_order_position= position
        else
          self.position_position= position
        end
      end
    end

    after_save if: :reindex_order do
      if section_id && (section_order_before_last_save != section_order)
        overral_pos = form.sections.reduce(0) do |sum, s|
          if s.id != section_id
            sum + s.fields_count.to_i
          else
            break sum + section_order_rank
          end
        end
        update(position_position: overral_pos)
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
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :section_order, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :section_id, absence: true, if: proc{|f| f.form && f.form.type == 'Document::NestedForm' }
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
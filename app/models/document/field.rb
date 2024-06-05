module Document
  class Field < ApplicationRecord
    include Document::Concerns::Models::Field
    include Document::Concerns::Models::Fields::Helper
    include Document::Concerns::Models::ActsAsGridField

    serialize :validations, ::Document::FieldOptions
    serialize :options, ::Document::FieldOptions

    self.table_name = "document_fields"

    belongs_to :form, class_name: 'Document::BareForm', touch: true, optional: true, inverse_of: :fields, counter_cache: true, foreign_key: 'form_id'
    belongs_to :section, class_name: Document.section_model_class, touch: true, optional: true, inverse_of: :fields, counter_cache: true, foreign_key: "section_id"
    #has_one :nested_form, class_name: 'Document::BareForm', as: :attachable, dependent: :destroy, inverse_of: :attachable
    has_one :nested_form, class_name: 'Document::NestedForm', dependent: :destroy, inverse_of: :attachable, foreign_key: "attachable_id"
    accepts_nested_attributes_for :nested_form, allow_destroy: true
    belongs_to :field_group, class_name: "Document::FieldGroup", touch: true, optional: true, inverse_of: :fields

    include Document::Concerns::Models::Cachers::Field

    scope :only_belongs_to_section, -> { where.not(section_id: nil) }
    scope :only_not_belongs_to_section, -> { where(section_id: nil) }

    before_validation do
      if form_id.blank?
        if section
          if section.form_id
            self.form_id= section.form_id
          else
            self.form= section.form
          end
        end
      end
      self.data_type = stored_type
    end

    positioned on: :form, column: :position_on_form
    positioned on: :section, column: :position_on_section

    attr_accessor :set_position_on_form
    attr_accessor :set_position_on_section

    def set_position_on_form=(value)
      @set_position_on_form=value
      self.position_on_form= value
    end

    def set_position_on_section=(value)
      @set_position_on_section= value
      self.position_on_section= value
    end

    def position_on_form
      if section_id.present? && _section= cached_section || section
        _section.position.to_i + position_on_section.to_i
      else
        read_attribute :position_on_form
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
    validates :section, absence: true, if: proc{|f|
      f.form && f.form.type == 'Document::NestedForm'
    }
    validates :section, presence: true, if: proc{|f|
      f.form && f.form.type != 'Document::NestedForm'
    }

    validates :section_id, inclusion: { in: proc{|f| f.form.sections.pluck(:id) } }, if: proc{|f|
      f.form && f.form.type != 'Document::NestedForm' && f.section_id.present?
    }

    validate do
      if persisted?
        errors.add(:name, :invalid) if name_in_database.to_s != name.to_s
      end
    end

    # validates :position_on_form, absence: true, if: proc { section.present? }
    # validates :position_on_section, absence: true, if: proc { section.blank? }

    default_value_for :name,
                      ->(_) { "field_#{SecureRandom.hex(3)}" },
                      allow_nil: false

    def self.type_key
      model_name.name.demodulize.underscore.to_sym
    end

    def type_key
      self.class.type_key
    end

    def clear_association_cache
      if defined?(super)
        super
      end
      if depedency_field?
        options.reset_instance_variables
      end
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
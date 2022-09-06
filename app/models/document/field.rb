module Document
  class Field < ApplicationRecord
    include Document::Concerns::Models::Field
    include Document::Concerns::Models::Fields::Helper

    self.table_name = "document_fields"

    belongs_to :form, class_name: 'Document::BareForm', touch: true, optional: true, inverse_of: :fields
    belongs_to :section, class_name: "Document::Section", touch: true, optional: true, inverse_of: :fields
    has_one :nested_form, as: :attachable, dependent: :destroy, inverse_of: :attachable
    accepts_nested_attributes_for :nested_form, allow_destroy: true
    belongs_to :field_group, class_name: "Document::FieldGroup", touch: true, optional: true, inverse_of: :fields

    before_validation do
      if form_id.blank?
        if section
          self.form = section.form
        end
      end
      self.data_type = stored_type
    end


    include RankedModel
    ranks :position, with_same: [:section_id, :form_id], class_name: self.name

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

    # default_value_for :name,
    #                   ->(_) { "field_#{SecureRandom.hex(3)}" },
    #                   allow_nil: false

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
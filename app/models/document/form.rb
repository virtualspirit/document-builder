module Document
  class Form < BareForm

    has_many :sections, -> { rank(:position) }, class_name: "Document::Section", dependent: :destroy, inverse_of: :form, index_errors: true
    belongs_to :owner, polymorphic: true, optional: true
    belongs_to :documentable, polymorphic: true, optional: true
    accepts_nested_attributes_for :sections, allow_destroy: true

    serialize :step_options, FormStepOptions

    before_save do
      if will_save_change_to_attribute?(:step)
        if step
          step_options.total = sections.count
        end
      end
    end

    after_initialize do
      if respond_to? :step_options
        self.step_options ||= {}
      end
    end

    alias_method :segments=, :sections_attributes=
    alias_method :steps, :sections
    alias_method :steps=, :sections_attributes=

    NAME_REGEX = /\A[a-z][a-z_0-9]*\z/.freeze

    validates :name,
              presence: true,
              uniqueness: { scope: [:documentable_id, :documentable_type] },
              exclusion: { in: Document.reserved_names },
              format: { with: NAME_REGEX }

    validates :title, presence: true
    validates :name, presence: true

    after_create :auto_create_default_section

    def virtual_fields instance, _fields = nil
      _fields ||= fields
      _fields.map do |field|
        vp = present_virtual_field(field, target: instance)
        if field.nested_form && vp.value
          if vp.multiple_nested_form?
            field.nested_form.virtual_fields = []
            vp.value.each do |nested_instance|
              field.nested_form.virtual_fields << virtual_fields(nested_instance, field.nested_form.fields)
            end
          else
            field.nested_form.virtual_fields = virtual_fields vp.value_for_preview, field.nested_form.fields
          end
        end
        vp
      end.reject(&:access_hidden?)
    end

    private

    def auto_create_default_section
      if sections.blank?
        sections.create! title: I18n.t("defaults.section.title"), headless: true
      end
    end

    protected

    def present_virtual_field(model, options = {})
      klass = options.delete(:presenter_class) || "#{model.class}Presenter".constantize
      presenter = klass.new(model, self, options)

      yield(presenter) if block_given?

      presenter
    end
  end
end

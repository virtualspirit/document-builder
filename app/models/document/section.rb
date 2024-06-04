module Document
  class Section < ApplicationRecord

    include Document::Concerns::Models::ActsAsGridSection

    self.table_name = "document_sections"

    belongs_to :form, touch: true, inverse_of: :sections, class_name: 'Document::Form', counter_cache: true, foreign_key: "form_id"
    has_many :fields, -> { order(:position_on_section) }, dependent: :destroy, inverse_of: :section, index_errors: true, class_name: "Document::Field", foreign_key: "section_id"
    accepts_nested_attributes_for :fields, allow_destroy: true
    alias_method :inputs=, :fields_attributes=

    include Document::Concerns::Models::Cachers::Section

    positioned on: :form

    attr_accessor :set_position

    def set_position=(val)
      @set_position= val
      self.position= val
    end

    before_validation do
      if headless && title.blank?
        self.title = SecureRandom.hex(5)
      end
    end

    validates :title, presence: true, uniqueness: { scope: [:form_id], allow_nil: true }, unless: :headless
    #validates :position, numericality: { only_integer: true, allow_blank: true }

    after_create do
      if form.present? and form.step
        form.step_options.total = form.sections.count
        form.save
      end
    end

    after_destroy do
      if form.present? and form.step
        form.step_options.total = form.sections.count
        form.save
      end
    end

    def virtual_fields instance, _fields = nil
      _fields ||= fields.sort_by(&:position_on_section)
      _fields.map do |field|
        vp = present_virtual_field(field, target: instance)
        nested_form = field.nested_form
        if nested_form && vp.value
          nested_fields = nested_form.fields.sort_by(&:position_on_form)
          unless nested_fields.blank?
            if vp.multiple_nested_form?
              nested_form.virtual_fields = []
              vp.value.each do |nested_instance|
                nested_form.virtual_fields << virtual_fields(nested_instance, nested_fields)
              end
            else
              nested_form.virtual_fields = virtual_fields(vp.value_for_preview, nested_fields)
            end
          end
        end
        vp
      end.reject(&:access_hidden?)
    end

    def _virtual_fields instance, _fields=nil
      _fields ||= cached_fields.sort_by(&:position_on_section)
      _fields.map do |field|
        if field.attached_nested_form? && instance.send("#{field.name}").blank?
          if instance.send("#{field.name}").nil?
            instance.send("build_#{field.name}")
          else
            instance.send("#{field.name}").build
          end
        end
        vp = present_virtual_field(field, target: instance)
        vp
      end.reject(&:access_hidden?)
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

module Document
  class Section < ApplicationRecord

    include Document::Concerns::Models::ActsAsGridSection

    self.table_name = "document_sections"

    belongs_to :form, touch: true, inverse_of: :sections, class_name: 'Document::BareForm', counter_cache: true

    has_many :fields, -> { order(:section_order) }, dependent: :destroy, inverse_of: :section, index_errors: true
    accepts_nested_attributes_for :fields, allow_destroy: true
    alias_method :inputs=, :fields_attributes=

    include RankedModel
    ranks :position, with_same: [:form_id]
    attr_accessor :reindex_order

    def reindex_order!
      self.reindex_order= true
    end

    before_validation do
      if headless && title.blank?
        self.title = SecureRandom.hex(5)
      end
    end

    after_validation if: :reindex_order do
      if position_was != position && !position.nil?
        self.position_position= position
      end
    end

    validates :title, presence: true, uniqueness: { scope: [:form_id], allow_nil: true }, unless: :headless
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }

    after_create do
      if form.present? and form.step
        form.step_options.total = form.step_options.total + 1
        form.save
      end
    end

    after_destroy do
      if form.present? and form.step
        form.step_options.total = form.step_options.total - 1
        form.save
      end
    end

    def virtual_fields instance, _fields = nil
      _fields ||= fields.order(:section_order)
      _fields.map do |field|
        vp = present_virtual_field(field, target: instance)
        if field.nested_form && vp.value
          if vp.multiple_nested_form?
            field.nested_form.virtual_fields = []
            vp.value.each do |nested_instance|
              field.nested_form.virtual_fields << virtual_fields(nested_instance, field.nested_form.fields.order(:position))
            end
          else
            field.nested_form.virtual_fields = virtual_fields(vp.value_for_preview, field.nested_form.fields.order(:position))
          end
        end
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

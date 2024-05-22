module Document
  class Section < ApplicationRecord

    include Document::Concerns::Models::ActsAsGridSection

    self.table_name = "document_sections"

    belongs_to :form, touch: true, inverse_of: :sections, class_name: 'Document::BareForm', counter_cache: true
    has_many :fields, -> { rank(:position_on_section) }, dependent: :destroy, inverse_of: :section, index_errors: true
    accepts_nested_attributes_for :fields, allow_destroy: true
    alias_method :inputs=, :fields_attributes=

    include Document::Concerns::Models::Cachers::Section

    # include ::IdentityCache
    # cache_belongs_to :form
    # cache_has_many :fields, embed: true

    include RankedModel
    ranks :position, with_same: [:form_id]

    attr_accessor :set_position

    def set_position=(val)
      @set_position= val
      self.position_position= val
    end

    before_validation do
      if headless && title.blank?
        self.title = SecureRandom.hex(5)
      end
    end

    after_validation do
      if position_was != position && !position.nil?
        self.position_position= position
      end
    end

    validates :title, presence: true, uniqueness: { scope: [:form_id], allow_nil: true }, unless: :headless
    #validates :position, numericality: { only_integer: true, allow_blank: true }

    after_create do
      if form.present? and form.step
        form.step_options.total = form.step_options.total + 1
        form.save
      end
    end

    after_save :rearange_fields_position_on_form, if: proc{ saved_change_to_position? }

    def rearange_fields_position_on_form
      # overral_pos = 0
      # form.fetch_sections.sort_by(&:position).each_with_index do |section, si|
      #   section.fetch_fields.sort_by(&:position_on_section).each_with_index do |field, fi|
      #     field.update_column(position_on_form: overral_pos)
      #     field.expire_cache
      #   end
      #   section.expire_cache
      # end

      old_position = position_before_last_save
      new_position = position
      position_difference = new_position - old_position
      fields.update_all("position_on_form = position_on_form + #{position_difference}")
      form.fields
      .where.not(section_id: id).where("position_on_form >= ? AND position_on_form <= ?", new_position, old_position)
      .update_all("position_on_form = position_on_form + #{position_difference}")
    end

    after_destroy do
      if form.present? and form.step
        form.step_options.total = form.step_options.total - 1
        form.save
      end
    end

    def virtual_fields instance, _fields = nil
      _fields ||= cacher.fields.sort_by(:position_on_section)
      _fields.map do |field|
        vp = present_virtual_field(field, target: instance)
        nested_form = field.cacher.nested_form
        if nested_form && vp.value
          nested_fields = nested_form.cacher.fields.sort_by(&:position_on_form)
          if vp.multiple_nested_form?
            nested_form.virtual_fields = []
            vp.value.each do |nested_instance|
              nested_form.virtual_fields << virtual_fields(nested_instance, nested_fields)
            end
          else
            nested_form.virtual_fields = virtual_fields(vp.value_for_preview, nested_fields)
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

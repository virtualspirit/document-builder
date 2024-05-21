module Document
  class NestedForm < BareForm

    belongs_to :nested_form_field, -> { where(document_forms: { attachable_type: 'Document::Field' }) }, foreign_key: 'attachable_id', class_name: "Document::Field", optional: true

    validates :attachable, presence: true

    attr_accessor :virtual_fields

    before_save do
      if attachable
        self.name = attachable.name
      end
    end

    cache_this :cached_attachable do
      value do |form|
        form.attachable
      end
      before_invalidate do |form|
        form.cached_attachable.try :invalidate_cache_of_cached_nested_form
      end
    end

    # def to_virtual_model(model_name: virtual_model_name,
    #                         fields_scope: proc { |fields| fields },
    #                         overrides: {})
    #   model = virtual_model model_name
    #   set_constant model_name, model
    #   append_to_virtual_model(model, fields_scope: fields_scope, overrides: overrides)
    # end

    def get_virtual_fields instance, _fields = nil
      _fields ||= cached_fields.sort_by(&:position_on_form)
      _fields.map do |field|
        vp = present_virtual_field(field, target: instance)
        nested_form = field.cached_nested_form
        if nested_form && vp.value_for_preview
          nested_fields = nested_form.cached_fields.sort_by(&:position_on_form)
          if vp.multiple_nested_form?
            nested_form.virtual_fields = []
            vp.value_for_preview.each do |nested_instance|
              field.nested_form.virtual_fields << get_virtual_fields(nested_instance, nested_fields)
            end
          else
            field.nested_form.virtual_fields = get_virtual_fields(vp.value_for_preview, nested_fields)
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

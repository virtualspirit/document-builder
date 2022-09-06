module Document
  class NestedForm < BareForm

    belongs_to :attachable, polymorphic: true, touch: true, inverse_of: :nested_form

    attr_accessor :virtual_fields

    before_save do
      if attachable
        self.name = attachable.name
      end
    end

    def get_virtual_fields instance, _fields = nil
      _fields ||= fields.rank(:position)
      _fields.map do |field|
        vp = present_virtual_field(field, target: instance)
        if field.nested_form && vp.value_for_preview
          if vp.multiple_nested_form?
            field.nested_form.virtual_fields = []
            vp.value_for_preview.each do |nested_instance|
              field.nested_form.virtual_fields << get_virtual_fields(nested_instance, field.nested_form.fields.rank(:position))
            end
          else
            field.nested_form.virtual_fields = get_virtual_fields(vp.value_for_preview, field.nested_form.fields.rank(:position))
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

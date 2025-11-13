module Document
  module Fields
    class DepedencyOneFieldPresenter < FieldPresenter

      def value_for_preview
        att = @model.options.display_value_field
        target.send(@model.name).try(att)
      end

      def virtual_model
        @virtual_model ||= @model.options.virtual_model
      end

      def choices
        @choices ||= @model.options.choices
      end

      def value
        target.send("#{@model.name}_id") rescue nil
      end

      def access_readonly?
        target.class.attr_readonly?("#{@model.name}_id")
      end

      def access_hidden?
        target.class.attribute_names.exclude?("#{@model.name}_id") && target.class.relations.keys.exclude?("#{@model.name}_id") rescue false
      end

      def access_read_and_write?
        !access_readonly? &&
          (target.class.attribute_names.include?("#{@model.name}_id") || target.class.relations.key?("#{@model.name}_id"))
      end

    end
  end
end

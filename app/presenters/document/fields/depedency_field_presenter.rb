module Document
  module Fields
    class DepedencyFieldPresenter < FieldPresenter

      # def initialize(model, section, options = {})
      #   super(model)

      #   @model = model
      #   @section = section
      #   @options = options
      #   @options.append_choices_as_json
      # end

      # def value_for_preview
      #   virtual_model.find(value)
      # end

      def value_for_preview
        val = target&.send(@model.name)
        if val
          val.send(@model.options.display_value_field)
        end
      end

      def value
        target&.send("#{@model.name}_id")
      end

      def virtual_model
        @virtual_model ||= @model.options.virtual_model
      end

      def choices
        @choices ||= @model.options.choices
      end

      def access_readonly?
        false
      end

      def access_hidden?
        target.class.attribute_names.exclude?(@model.name.to_s) && target.class.relations.keys.exclude?(@model.name.to_s) rescue false
      end

      def access_read_and_write?
        !access_readonly?
      end

      def depedency_field?
        true
      end

    end
  end
end

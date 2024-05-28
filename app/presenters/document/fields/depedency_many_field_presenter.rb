module Document
  module Fields
    class DepedencyManyFieldPresenter < FieldPresenter

      # def initialize(model, section, options = {})
      #   super(model)

      #   @model = model
      #   @section = section
      #   @options = options
      #   @options.append_choices_as_json
      # end

      def value_for_preview
        att = @model.options.display_value_field
        target&.send(@model.name).map{|v| v.send(att) }.join(",")
      end

      def choices
        @choices ||= @model.options.choices
      end

      # def value
      #   begin
      #     target.send("#{@model.name}_ids")
      #   rescue => e
      #     puts e.backtrace
      #   end
      # end

      def value
        target.send("#{@model.name}_ids") rescue []
      end

      def multiple_depedency_field?
        false
      end

      def access_readonly?
        target.class.attr_readonly?("#{@model.name}_ids")
      end

      def access_hidden?
        target.class.attribute_names.exclude?("#{@model.name}_ids") && target.class.relations.keys.exclude?("#{@model.name}_ids") rescue false
      end

      def access_read_and_write?
        !access_readonly? &&
          (target.class.attribute_names.include?("#{@model.name}_ids") || target.class.relations.key?("#{@model.name}_ids"))
      end

    end
  end
end

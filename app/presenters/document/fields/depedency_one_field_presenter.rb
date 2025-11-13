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
        begin
          target.send("#{@model.name}_id")
        rescue => e
          puts e.backtrace
        end
      end

    end
  end
end

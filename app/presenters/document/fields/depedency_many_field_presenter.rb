module Document
  module Fields
    class DepedencyManyFieldPresenter < FieldPresenter

      def value_for_preview
        att = @model.options.display_value_field
        target&.send(@model.name).map{|v| v.send(att) }.join(",")
      end

      def choices
        @choices ||= @model.options.choices
      end

      def value
        begin
          target.send("#{@model.name}_ids")
        rescue => e
          puts e.backtrace
        end
      end

    end
  end
end

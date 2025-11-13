module Document
  module Fields
    class CompositeFieldPresenter < FieldPresenter
      def value
        target&.send(@model.name)
      end

      def value_for_preview
        target&.send(@model.name)
      end

      # def access_readonly?
      #   begin
      #   target.class.attr_readonly?(@model.name)
      #   rescue => e
      #     debugger
      #     raise e
      #   end
      # end

      # def access_hidden?
      #   target.class.attribute_names.exclude?(@model.name.to_s) && target.class.relations.keys.exclude?(@model.name.to_s) rescue false
      # end

      # def access_read_and_write?
      #   !access_readonly? &&
      #     (target.class.attribute_names.include?(@model.name.to_s) || target.class.relations.key?(@model.name.to_s))
      # end

    end
  end
end

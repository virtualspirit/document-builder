module Document
  class Fields::FieldPresenter < ApplicationPresenter

    def required
      if @model.validations.attributes[:required].present?
        @model.validations&.required
      else
        false
      end
    end
    alias required? required

    def target
      @options[:target]
    end

    def value
      begin
        target&.read_attribute(@model.name)
      rescue => e
        puts e.backtrace
      end
    end

    def value_for_preview
      target&.read_attribute(@model.name)
    end

    def access_readonly?
      target.class.attr_readonly?(@model.name)
    end

    def access_hidden?
      target.class.attribute_names.exclude?(@model.name.to_s) && target.class.relations.keys.exclude?(@model.name.to_s) rescue false
    end

    def access_read_and_write?
      !access_readonly? &&
        (target.class.attribute_names.include?(@model.name.to_s) || target.class.relations.key?(@model.name.to_s))
    end

    def id
      "form_field_#{@model.id}"
    end

    def nested_form_field?
      false
    end

    def multiple_nested_form?
      false
    end

    def depedency_field?
      false
    end

    def multiple_depedency_field?
      false
    end

  end
end
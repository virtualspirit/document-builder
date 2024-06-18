module Document
  module Fields
    class TimeRangeField < Document::Field

      serialize :validations, Validations::TimeRangeField
      serialize :options, Options::TimeRangeField

      def stored_type
        :date_time
      end

      def range_field?
        true
      end

      def interpret_as_field_for model, overrides: {}
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        nested_model = Document::Fields::Embeds::TimeRange

        model.nested_models[name] = nested_model

        model.embeds_one name, class_name: nested_model.name#, validate: true
        model.accepts_nested_attributes_for name, reject_if: :all_blank
        field_name = name
        model.after_initialize do
          send("build_#{field_name}") unless send("#{field_name}")
        end
        model.validate do
          if send(field_name).present? && !send(field_name).valid?
            send(field_name).errors.each {|e| errors.import e, **e.options.merge(attribute: "#{field_name}.#{e.attribute}")}
          end
        end
        model.add_as_searchable_field name if options.try(:searchable)
        model
      end

    end
  end
end

module Document
  module Fields
    class TimeRangeField < Document::Field

      serialize :validations, Validations::TimeRangeField
      serialize :options, Options::TimeRangeField

      def stored_type
        :date_time
      end

      protected

      def interpret_as_field_for model, overrides: {}
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        nested_model = Document::Fields::Embeds::TimeRange

        model.nested_models[name] = nested_model

        model.embeds_one name, class_name: nested_model.name, validate: true
        model.accepts_nested_attributes_for name, reject_if: :all_blank
        model.add_as_searchable_field name if options.try(:searchable)
        model
      end

    end
  end
end

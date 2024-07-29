module Document
  module Fields
    class TimeRangeField < Document::Field

      serialize :validations, Validations::TimeRangeField
      serialize :options, Options::TimeRangeField

      include Document::Fields::Embeds::EmbeddedVirtualModel::Core

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

        nested_model = embedded_virtual_model

        model.nested_models[name] = nested_model

        model.embeds_one name, class_name: nested_model.name#, validate: true
        model.accepts_nested_attributes_for name, reject_if: :all_blank, allow_destroy: true
        field_name = name
        model.after_initialize do
          #send("build_#{field_name}") unless send("#{field_name}")
        end

        nested_model.embedded_in model.name.underscore.to_sym, class_name: model.name, inverse_of: field_name

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

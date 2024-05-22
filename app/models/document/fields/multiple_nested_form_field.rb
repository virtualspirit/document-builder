module Document
  module Fields
    class MultipleNestedFormField < Document::Field

      after_create do
        build_nested_form.save! unless nested_form.present?
      end

      serialize :validations, Validations::MultipleNestedFormField
      serialize :options, Options::MultipleNestedFormField

      def attached_nested_form?
        true
      end

      # def interpret_as_field_for model, overrides: {}
      #   check_model_validity!(model)

      #   accessibility = overrides.fetch(:accessibility, self.accessibility)
      #   return model if accessibility == :hidden

      #   overrides[:name] = name

      #   nested_model = nested_form.to_virtual_model(overrides: { _global: { accessibility: accessibility } })

      #   model.nested_models[name] = nested_model

      #   model.embeds_many name, class_name: nested_model.name, validate: true
      #   nested_model.embedded_in model.name.downcase.to_sym, class_name: model.name
      #   model.accepts_nested_attributes_for name, reject_if: :all_blank, allow_destroy: true
      #   model
      # end

      def interpret_as_field_for model, overrides: {}
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        overrides[:name] = name
        nested_model = cacher.nested_form.to_virtual_model(overrides: { _global: { accessibility: accessibility } })
        if nested_model
          nested_model.field "#{name}_id", type: BSON::ObjectId
          model.field "#{name}_count".to_sym, type: :integer, default: 0
          model.has_many name, class_name: nested_model.name, foreign_key: "#{name}_id"
          nested_model.belongs_to model.name.downcase.to_sym, class_name: model.name, optional: true, inverse_of: "#{name}".to_sym, counter_cache: "#{name}_count".to_sym
          model.accepts_nested_attributes_for name, reject_if: :all_blank, allow_destroy: true

          model.class_eval <<-CODE
            def serializable_hash(options= nil)
              if options && options[:include]
                options[:include] = [options[:include]].compact unless options[:include].is_a?(Array)
                options[:include] << '#{name}'.to_sym
              else
                unless options.is_a?(Hash)
                  options={}
                end
                options[:include]= '#{name}'.to_sym
              end
              super(options)
            end
          CODE
          # if options.try(:searchable)
          #   nested_model.fields.each do |arr, f|
          #     model.add_as_searchable_field({field_name.to_sym => f.name.to_sym}) if f.options.try(:searchable)
          #   end
          # end
          interpret_validations_to model, accessibility, overrides
          interpret_extra_to model, accessibility, overrides
        end
        model
      end

      # def interpret_to(model, overrides: {})
      #   mode
      #   model.attr_readonly name if accessibility == :readonly

      #   interpret_validations_to model, accessibility, overrides
      #   interpret_extra_to model, accessibility, overrides

      #   model
      # end

    end
  end
end

module Document
  module Fields
    class GeolocationField < Document::Field

      serialize :validations, Validations::GeolocationField
      serialize :options, Options::GeolocationField

      def stored_type
        :string
      end

      def interpret_as_field_for(model, overrides: {})
        check_model_validity!(model)

        accessibility = overrides.fetch(:accessibility, self.accessibility)
        return model if accessibility == :hidden

        field_name = name
        model.include ::Mongoid::Geospatial
        model.field field_name, type: ::Mongoid::Geospatial::Point, spatial: true
        model.field "#{id}#{options.location_field_suffix_name}", type: :string

        model.add_as_searchable_field field_name if options.try(:searchable)
        model
      end

      def interpret_to(model, overrides: {})
        model = interpret_as_field_for model, overrides: overrides
        model.attr_readonly field_name if accessibility == :readonly

        # model.before_save do
        #   if will_save_change_to_attribute?(field_name)
        #     send("#{field_name}=", send("#{field_name}").map(&:to_f))
        #   end
        # end
        # model.after_save do
        #   if saved_change_to_attribute?(field_name)
        #     model.remove_indexes
        #     model.create_indexes
        #   end
        # end

        interpret_validations_to model, accessibility, overrides
        interpret_extra_to model, accessibility, overrides

        model
      end

      protected

        def interpret_extra_to(model, accessibility, _overrides = {})
          return if accessibility != :read_and_write
          unless defined?(Geocoder)
            raise "please install geocoder gem"
          end

          fill_method = options.fill_method
          suffix_method = "#{id}#{options.location_field_suffix_name}"
          field_name = name
          if ['automatic', 'automatic_with_location'].include?(fill_method)
            model.before_validation do
              if self.send("#{suffix_method}_changed?")
                begin
                  res = ::Geocoder.search(self.send(suffix_method)).first
                  if res
                    _coordinates_ = []
                    _coordinates_ << res.longitude
                    _coordinates_ << res.latitude
                    self.send("#{field_name}=", _coordinates_)
                  end
                rescue => e
                  self.send("#{field_name}=", nil)
                end
              end
            end
          end
        end

    end
  end
end
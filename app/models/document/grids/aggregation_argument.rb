module Document
  module Grids

    class AggregationArgument < Document::FieldOptions

      module ParemetersExtension

        def to_arguments parameters_as_array
          if parameters_as_array
            self.map do |arg|
              arg.to_argument
            end
          else
            self.reduce({}) do |hash, arg|
              args = arg.to_argument
              if args.is_a?(Hash)
                hash.merge! arg.to_argument
              end
              hash
            end
          end
        end

      end

      attribute :function
      attribute :raw_parameter
      attribute :parameter
      attribute :blank_parameter, :boolean, default: false
      attribute :parameters_as_array, :boolean, default: true

      embeds_many :parameters, class_name: self.name, extend: ParemetersExtension
      accepts_nested_attributes_for :parameters, allow_destroy: true

      def to_argument
        if blank_parameter
          { "#{function}": nil }
        else
          if raw_parameter.present?
            {
              "#{function}": raw_parameter
            }
          else
            if parameters.present?
              {
                "#{function}".to_sym => parameters.to_arguments(parameters_as_array)
              }
            else
              if parameter.nil?
                "#{function}"
              else
                { "#{function}".to_sym => parameter }
              end
            end
          end
        end
      end

    end

  end
end
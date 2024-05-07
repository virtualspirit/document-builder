module Document
  module Grids
    module Fields
      class MultipleNestedColumn < ::Document::Grids::Field

        include Concerns::Default
        include Concerns::Nested

        self.valid_field_types = ['Document::Fields::MultipleNestedFormField', 'Document::Fields::DepedencyManyField']

        def to_virtual_view
          if viewable
            @virtual_view ||= field.options.form.to_virtual_view
          end
        end

        def build_default_aggregation
          if name
            if field.attached_nested_form?
              super if grid.is_panel?
              aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_count", parameter: 1}])
            else
              aggregation.stages = []
              super if grid.is_panel?
              if field.depedency_field?
                aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_ids", parameter: 1}])
                aggregation.stages.build({
                  name: "$addFields", merge: false, order: 9996, arguments_attributes: [
                    {
                      function: "#{name}_ids",
                      raw_parameter: {
                        "$cond": {
                          "if": {
                            "$ne": [
                              {
                                "$type": "$#{name}_ids"
                              },
                              "array"
                            ]
                          },
                          "then": [],
                          "else": "$#{name}_ids"
                        }
                      }
                    }
                  ]
                })
                aggregation.stages.build(name: "$addFields", merge: false, order: 9997,
                  arguments_attributes: [
                    function: "#{name}_count",
                    raw_parameter: {
                      "$size": "$#{"#{name}_ids"}"
                    }
                  ]
                )
                aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_count", parameter: 1}])
              end
            end
          end
        end

        def multiple?
          true
        end

        # def build_aggregation
        #   if field.attached_nested_form?
        #     form = field.nested_form
        #   else
        #     form = field.options.form
        #   end
        #   if form
        #     stages = []
        #     lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9999)
        #     lookup.arguments.build(function: "from", parameter: form.collection_name)
        #     lookup.arguments.build(function: "as", parameter: name)
        #     if field.depedency_field?
        #       stages << AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_id", parameter: 1}])
        #       lookup.arguments.build(function: "localField", parameter: "#{name}_id")
        #       lookup.arguments.build(function: "foreignField", parameter: "_id")
        #     else
        #       stages << AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}", parameter: 1}])
        #       lookup.arguments.build(function: "localField", parameter: "_id")
        #       lookup.arguments.build(function: "foreignField", parameter: "#{name}_id")
        #     end
        #     stages << lookup
        #     unwind = AggregationStage.new(
        #       name: "$unwind",
        #       merge: false,
        #       parameters_as_array: false,
        #       order: 9998,
        #       arguments_attributes: [
        #         { function: "path", parameter: "$#{name}" },
        #         { function: "preserveNullAndEmptyArrays", parameter: true }
        #       ]
        #     )
        #     stages << unwind
        #     aggregation_stages = stages
        #   end
        #   aggregation
        # end


        # def build_aggregation
        #   if field.attached_nested_form?
        #     form = field.nested_form
        #   else
        #     form = field.options.form
        #   end
        #   if form
        #     stages = []
        #     lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9999)
        #     lookup.arguments.build(function: "from", parameter: form.collection_name)
        #     lookup.arguments.build(function: "as", parameter: name)
        #     if field.depedency_field?
        #       stages << AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_id", parameter: 1}])
        #       lookup.arguments.build(function: "localField", parameter: "#{name}_id")
        #       lookup.arguments.build(function: "foreignField", parameter: "_id")
        #       # matches = {}
        #       # clauses.each do |c|
        #       #   matches.deep_merge!(c.to_criteria) if c.to_criteria.is_a?(Hash)
        #       # end
        #       # pipeline = Aggregation.new
        #       # pipeline.stages.build({name: "$match", arguments_attributes: matches.reduce([]){|arr, h| arr << { function: h[0], raw_parameter: h[1] } }})
        #       # if matches.present?
        #       #   lookup.arguments.build function:  "pipeline", pipeline: pipeline
        #       # end
        #     end
        #     stages << lookup
        #     unwind = AggregationStage.new(
        #       name: "$unwind",
        #       merge: false,
        #       parameters_as_array: false,
        #       order: 9998,
        #       arguments_attributes: [
        #         { function: "path", parameter: "$#{name}" },
        #         { function: "preserveNullAndEmptyArrays", parameter: true }
        #       ]
        #     )
        #     stages << unwind
        #     aggregation_stages = stages
        #   end
        #   aggregation
        # end

      end
    end
  end
end
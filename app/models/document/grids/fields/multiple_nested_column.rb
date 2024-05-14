module Document
  module Grids
    module Fields
      class MultipleNestedColumn < ::Document::Grids::Field

        include Concerns::Default
        include Concerns::Nested

        self.valid_field_types = ['Document::Fields::MultipleNestedFormField', 'Document::Fields::DepedencyManyField']

        def to_virtual_view
          if form
            @virtual_view ||= field.options.form.to_virtual_view
          end
        end

        def build_default_aggregation(grid_container = nil)
          if default_aggregation
            if name
              if field.attached_nested_form?
                super if grid_container && grid_container.is_panel?
                aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_count", parameter: 1}])
              else
                aggregation.stages = []
                super if grid_container && grid_container.is_panel?
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
        end

        def multiple?
          true
        end

      end
    end
  end
end
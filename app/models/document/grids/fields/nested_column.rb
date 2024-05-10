module Document
  module Grids
    module Fields
      class NestedColumn < ::Document::Grids::Field

        include Concerns::Default
        include Concerns::Nested

        self.valid_field_types = ['Document::Fields::NestedFormField', 'Document::Fields::DepedencyOneField']

        def to_virtual_view
          if field && field.depedency_field?
            @virtual_view ||= field.options.form.to_virtual_view
          end
        end

        def build_default_aggregation
          if default_aggregation
            if name
              if field.attached_nested_form?
                super
              else
                aggregation.stages = []
                super
                aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_id", parameter: 1}])
              end
            end
          end
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

      end
    end
  end
end
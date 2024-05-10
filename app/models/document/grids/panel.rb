module Document
  module Grids
    class Panel < Document::Grid

      # has_many :sections, -> { rank(:position) }, class_name: "Document::Grids::Section", foreign_key: "grid_id", dependent: :destroy, index_errors: true\
      belongs_to :list, class_name: "Document::Grids::List", foreign_key: "list_id", optional: true
      # has_many :sections, through: :form, source: :sections
      accepts_nested_attributes_for :sections, allow_destroy: true

      #before_create :append_sections

      def is_panel?
        true
      end

      def build_default_aggregation
        aggregation.stages = []
        if nested_field
          aggregation.nested_stages = []
          lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                { function: "from", parameter: form.collection_name },
                { function: "localField", parameter: nested_field.depedency_field? ? "#{nested_field.name}_id" : "_id"},
                { function: "foreignField", parameter: nested_field.depedency_field? ? "_id" : "#{nested_field.name}_id"},
                { function: "as", parameter: nested_field.name },
              ])
          aggregation.nested_stages << lookup
          unwind = AggregationStage.new(
                  name: "$unwind",
                  merge: false,
                  parameters_as_array: false,
                  order: 9998,
                  arguments_attributes: [
                    { function: "path", parameter: "$#{nested_field.name}" },
                    { function: "preserveNullAndEmptyArrays", parameter: true }
                  ]
                )
          aggregation.nested_stages << unwind
        end
      end

      def fields_stages field_scope= proc{|field| field}
        stages = []
        fields.each do |field|
          if field_scope.call(field)
            field.build_default_aggregation if field.default_aggregation
            if field.nested?
              if field.multiple?
                stages = stages + field.grid_list.nested_aggregation_stages({}, field_scope)
              else
                stages = stages + field.grid_panel.nested_aggregation_stages({}, field_scope)
              end
            end
            stages = stages + field.aggregation.stages
          end
        end
        stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "created_at", parameter: 1}])
        stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "updated_at", parameter: 1}])
        stages
      end

      def data(params={}, field_scope = proc{|field| field})
        raw_stages = []
        res = virtual_view.where(id: params[:id])
        raw_stages << res.project(:id => "id").pipeline.filter{|p| p["$match"].present? }[0]
        aggregates = raw_stages + to_aggregation(params, field_scope)
        virtual_view.collection.aggregate(aggregates).first
      end

    end
  end
end
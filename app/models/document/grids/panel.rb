module Document
  module Grids
    class Panel < Document::Grid

      belongs_to :list, class_name: "Document::Grids::List", foreign_key: "list_id", optional: true
      has_many :sections, -> {rank(:position)}, class_name: "Document::Section", foreign_key: "form_id", primary_key: "form_id", inverse_of: :grid
      #has_many :sections, -> { rank(:position) }, through: :form, source: :sections

      #before_create :append_sections

      validate do
        if self.nested_field
          errors.add(:nested_field, :invalid) unless nested_field.nested? && !nested_field.multiple?
        end
      end

      before_create do
        if self.nested_field
          if nested_field.multiple?
            if nested_field.nested_grid_list
              self.list_id= nested_field.nested_grid_list.id
            end
          end
        end
      end

      def is_panel?
        true
      end

      def build_default_aggregation
        aggregation.stages = []
        if nested_field
          aggregation.nested_stages = []
          lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                { function: "from", parameter: cached_form.collection_name },
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

      def fields_stages(field_scope= proc{|field, grid| field})
        stages = []
        _fields= field_scope.call(cached_fields, self)
        _fields.each do |field|
          if field.nested?
            # nested_grid = if field.multiple?
            #   field.nested_grid_list
            # else
            #   field.nested_grid_panel
            # end
            # if nested_grid
            #   nested_grid.nested_field= field
            #   nested_grid.build_default_aggregation if nested_grid.default_aggregation
            #   stages = stages + nested_grid.nested_aggregation_stages({}, field_scope)
            # end
            if field.multiple?
              stages = stages + field.build_default_nested_grid_list_aggregation({}, field_scope)
            else
              stages = stages + field.build_default_nested_grid_panel_aggregation({}, field_scope)
            end
          end
          if field.default_aggregation
            field.multiple?? field.build_default_aggregation(self) : field.build_default_aggregation
          end
          stages = stages + field.aggregation.stages
        end
        # stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "created_at", parameter: 1}])
        # stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "updated_at", parameter: 1}])
        stages
      end

      def data(params={}, field_scope = proc{|field, grid| field})
        raw_stages = []
        res = virtual_view.where(id: params[:id] || params[:instance_id])
        raw_stages << res.project(:id => "id").pipeline.filter{|p| p["$match"].present? }[0]
        aggregates = raw_stages + to_aggregation(params, field_scope)
        virtual_view.collection.aggregate(aggregates).first
      end

    end
  end
end
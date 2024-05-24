module Document
  module Grids
    module Fields
      module Concerns

        module Default

          extend ActiveSupport::Concern
          included do

            attr_accessor :prevent_default_destroy

            validates :field, presence: true

            after_save do
              if field_id.present?
                if default && (default_previously_was == false || default_previously_was == nil)
                  self.class.where.not(id: self.id).where(default: true, field_id: field_id, type: self.type).update_all(default: false)
                end
              end
            end

            before_destroy do
              if default && prevent_default_destroy
                errors.add(:default, :invalid)
                throw :abort
              end
            end

          end

          def prevent_default_destroy!
            self.prevent_default_destroy= true
          end

          def build_default_aggregation(grid_container=nil)
            if default_aggregation
              if name
                aggregation.stages = []
                case field_type.demodulize.underscore
                when "geolocation_field"
                  aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}", parameter: 1}])
                  aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}#{cacher.field.options.location_field_suffix_name}", parameter: 1}])
                when "attachment_field"
                  aggregation.stages.build(name: "$addFields", merge: false, order: 9997,
                    arguments_attributes: [
                      function: "#{name}",
                      parameter: "$_#{name}_url"
                    ]
                  )
                  aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}", parameter: 1}])
                  aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_data", parameter: 1}])
                when "multiple_attachment_field"
                  aggregation.stages.build(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                    { function: "from", parameter: Document::Fields::Embeds::MultipleAttachment.collection_name.to_s },
                    { function: "localField", parameter: "_id"},
                    { function: "foreignField", parameter: "attachable_id"},
                    { function: "as", parameter: name },
                    { function: "pipeline", raw_parameter:
                      [
                        {"$addFields" => { "attachment": "$_attachment_url" }},
                        {"$project" => { "_id": 1, "attachment": 1, "attachment_data": 1 }}
                      ]
                    }
                  ])
                  aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}", parameter: 1}])
                else
                  aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}", parameter: 1}])
                end
              end
            end
          end

          def field_type
            cacher.field.try(:type) if field_id
          end

          def field_identifier
            cacher.field.try(:identifier) if field_id
          end

        end

        module Buildable

          extend ActiveSupport::Concern

          class_methods do

            def determine_field_klass field
              case field.type
              when "Document::Fields::NestedFormField"
                Document::Grids::Fields::NestedColumn
              when "Document::Fields::DepedencyOneField"
                Document::Grids::Fields::NestedColumn
              when "Document::Fields::MultipleNestedFormField"
                Document::Grids::Fields::MultipleNestedColumn
              when "Document::Fields::DepedencyManyField"
                Document::Grids::Fields::MultipleNestedColumn
              else
                Document::Grids::Fields::Column
              end
            end

            def build field, namespace = []
              klass = determine_field_klass(field)
              gf = klass.new(
                name: field.name,
                label: field.label,
                namespace: namespace,
                set_position_on_grid: field.position_on_form_rank,
                position_on_section: field.position_on_section,
                field: field,
                field_id: field.id,
                section_id: field.section_id
              )
              gf
            end

          end

        end

        module Nested

          extend ActiveSupport::Concern

          included do

            accepts_nested_attributes_for :nested_grid_list, reject_if: :all_blank
            accepts_nested_attributes_for :nested_grid_panel, reject_if: :all_blank

            validate :valid_field, if: :field

            after_save do
              if field_id.present?
                if default && (default_previously_was == false || default_previously_was == nil)
                  previous_default = self.class.where.not(id: self.id).where(default: true, field_id: field_id, type: self.type).each do |pd|
                    pd.nested_grids.update_all nested_field_id: self.id
                    pd.update_column :default, false
                  end
                end
              end
            end

            class_attribute :valid_field_types
            self.valid_field_types = []


          end

          def valid_field
            unless self.class.valid_field_types.include?(field.type)
              errors.add(:field, :invalid)
            end
          end

          def form
            if cacher.field.attached_nested_form?
              cacher.field.cacher.nested_form
            else
              cacher.field.options.form
            end
          end

          def depedency_field?
            cacher.field.try(:depedency_field?)
          end

          def has_attached_nested_form?
            cacher.field.try(:has_attached_nested_form?)
          end

          def nested?
            true
          end

          def multiple?
            false
          end

          def build_default_nested_grid_panel_aggregation(params={}, field_scope = proc{|field, nested_field=nil| field})
            cached_nested_grid_panel = cacher.nested_grid_panel
            if cached_nested_grid_panel && cached_nested_grid_panel.default_aggregation
              matches = {}
              if depedency_field? && field_type == "Document::Fields::DepedencyManyField"
                matches.deep_merge!({"$expr".to_sym => { "$in".to_sym => [ "$_id", "$$#{name}_ids" ] }})
              end
              agg = aggregation.class.new
              unless matches.blank?
                agg.stages.build({name: "$match", arguments_attributes: matches.reduce([]){|arr, h| arr << { function: h[0], raw_parameter: h[1] } }})
              end
              agg.stages.append(cached_nested_grid_panel.aggregation_stages(params.merge({nested_field: self}), field_scope))
              cached_nested_grid_panel.aggregation.nested_stages = []
              lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                { function: "from", parameter: cached_nested_grid_panel.cacher.form.collection_name },
                { function: "localField", parameter: depedency_field? ? "#{name}_id" : "_id"},
                { function: "foreignField", parameter: depedency_field? ? "_id" : "#{name}_id"},
                { function: "as", parameter: name },
                { function: "pipeline", raw_parameter: agg.to_aggregation }
              ])
              cached_nested_grid_panel.aggregation.nested_stages << lookup
              unwind = AggregationStage.new(
                name: "$unwind",
                merge: false,
                parameters_as_array: false,
                order: 9998,
                arguments_attributes: [
                  { function: "path", parameter: "$#{name}" },
                  { function: "preserveNullAndEmptyArrays", parameter: true }
                ]
              )
              cached_nested_grid_panel.aggregation.nested_stages << unwind
            end
            cached_nested_grid_panel ? cached_nested_grid_panel.aggregation.nested_stages : []
          end

          def build_default_nested_grid_list_aggregation(params={}, field_scope = proc{|field, nested_field=nil| field})
            cached_nested_grid_list = cacher.nested_grid_list
            if cached_nested_grid_list && cached_nested_grid_list.default_aggregation
              cached_nested_grid_list.aggregation.nested_stages = []
              matches = {}
              if depedency_field? && field_type == "Document::Fields::DepedencyManyField"
                matches.deep_merge!({"$expr".to_sym => { "$in".to_sym => [ "$_id", "$$#{name}_ids" ] }})
              end
              agg = aggregation.class.new
              unless matches.blank?
                agg.stages.build({name: "$match", arguments_attributes: matches.reduce([]){|arr, h| arr << { function: h[0], raw_parameter: h[1] } }})
              end
              agg.stages.append(cached_nested_grid_list.aggregation_stages(params.merge({nested_field: self}), field_scope))
              if depedency_field? && field_type == "Document::Fields::DepedencyManyField"
                lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                    { function: "from", parameter: cached_nested_grid_list.cacher.form.collection_name },
                    { function: "let", parameters_as_array: false, parameters_attributes: [
                        { function: "#{name}_ids", parameter: "$#{name}_ids" }
                      ]
                    },
                    { function: "as", parameter: name },
                    { function: "pipeline", raw_parameter: agg.to_aggregation }
                  ])
              else
                lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                      { function: "from", parameter: cached_nested_grid_list.cacher.form.collection_name },
                      { function: "localField", parameter: depedency_field? ? "#{name}_id" : "_id"},
                      { function: "foreignField", parameter: depedency_field? ? "_id" : "#{name}_id"},
                      { function: "as", parameter: name },
                      { function: "pipeline", raw_parameter: agg.to_aggregation }
                ])
              end
              cached_nested_grid_list.aggregation.nested_stages << lookup
              project = AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_count", parameter: 1}])
              cached_nested_grid_list.aggregation.nested_stages << project
            end
            cached_nested_grid_list ? cached_nested_grid_list.aggregation.nested_stages : []
          end

        end

      end
    end
  end
end

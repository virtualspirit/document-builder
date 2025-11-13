# create_table :document_grid_columns do |t|
#   t.references :field
#   t.references :nested_column
#   t.references :grid
#   t.string :name
#   t.string :label
#   t.string :namespace
#   t.integer :order
#   t.string :type
#   t.text :aggregation
#   t.timestamps
# end

module Document
  module Grids
    class Field < ApplicationRecord

      self.table_name = 'document_grid_fields'

      belongs_to :grid, class_name: 'Document::Grid'
      belongs_to :nested_column, class_name: "Document::Grids::Field::NestedColumn", optional: true

      serialize :namespace, Array
      serialize :aggregation, Document::Grids::Aggregation

      class AggregateColumn < Field
      end

      class Column < Field

        belongs_to :field, class_name: 'Document::Field', foreign_key: "field_id"

        delegate :to_aggregation, to: :aggregation

        def aggregation_stages
          aggregation.try(:stages) || []
        end

        after_initialize do
          if name
            if self.aggregation.blank?
              self.aggregation = Aggregation.new
            end
            if self.aggregation.stages.blank?
              self.aggregation.stages << AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: function_name, parameter: 1}])
            end
          end
        end

        def function_name
          (namespace || []).dup.append(name).join(".")
        end

        class << self


          def build grid, field, namespace = []
            column_name = field.name
            if field.is_a?(Document::Fields::DepedencyOneField)
              column_name = "#{field.name}_id"
            end
            if field.is_a?(Document::Fields::DepedencyManyField)
              column_name = "#{field.name}_ids"
            end
            column = self.new(
              grid_id: grid.id,
              grid: grid,
              field_id: field.id,
              name: column_name,
              label: field.label,
              namespace: namespace,
            )
            # if field.nested_form
            #   _namespace = namespace.dup << field.name
            #   (field.nested_form.try(:fields) || []).each do |f|
            #     column.columns << self.build(grid, f, _namespace)
            #   end
            # end
            column
          end

        end

      end

      class SubGridColumn < Field
      end

      class NestedColumn < Field

        belongs_to :field, class_name: 'Document::Field', foreign_key: "field_id"
        has_many :columns, class_name: 'Document::Grids::Field', foreign_key: "nested_column_id"
        accepts_nested_attributes_for :columns, allow_destroy: true

        def to_aggregation
          _aggregation = aggregation.class.new
          _aggregation.stages = aggregation_stages.flatten
          aggregation.to_aggregation
        end

        def function_name
          (namespace || []).dup.flatten.append(name).join(".")
        end

        def aggregation_stages
          stages = []
          return stages if field.nil? || columns.blank?

          if field.is_a?(Document::Fields::DepedencyOneField) || field.is_a?(Document::Fields::DepedencyManyField)
            form = field.options.form
            if form
              ref_col = Column.build(grid, field, namespace)
              clauses = field.options.clauses
              matches = {}
              if field.is_a?(Document::Fields::DepedencyOneField)
                matches.deep_merge!({"$expr".to_sym => { "$eq".to_sym => [ "$$#{ref_col.name}", "$_id" ] }})
              else
                matches.deep_merge!({"$expr".to_sym => { "$in".to_sym => [ "$_id", "$$#{ref_col.name}" ] }})
              end
              clauses.each do |c|
                matches.deep_merge!(c.to_criteria) if c.to_criteria.is_a?(Hash)
              end
              pipeline = Aggregation.new
              pipeline.stages.build({name: "$match", arguments_attributes: matches.reduce([]){|arr, h| arr << { function: h[0], raw_parameter: h[1] } }})
              columns.each do |column|
                column.aggregation_stages.each do |stg|
                  pipeline.stages << stg
                end
              end

              stages =[]

              if(field.is_a?(Document::Fields::DepedencyManyField))
                relation_field = AggregationStage.new({
                  name: "$addFields", merge: false, order: 9997, arguments_attributes: [
                    {
                      function: "#{ref_col.function_name}",
                      raw_parameter: {
                        "$cond": {
                          "if": {
                            "$ne": [
                              {
                                "$type": "$#{ref_col.function_name}"
                              },
                              "array"
                            ]
                          },
                          "then": [],
                          "else": "$#{ref_col.function_name}"
                        }
                      }
                    }
                  ]
                })
                stages << relation_field
              end

              if (ref_col.namespace.present?)
                ref_col.namespace.reduce([]){|arr, val|
                  if val.is_a?(Array)
                    unwind = AggregationStage.new(
                      name: "$unwind",
                      merge: false,
                      parameters_as_array: false,
                      order: 9996,
                      arguments_attributes: [
                        { function: "path", parameter: "$#{arr.concat(val).join(".")}" }
                      ]
                      )
                    stages << unwind
                  end
                  arr.append(val)
                }
              end

              lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                { function: "from", parameter: field.options.virtual_model.collection_name.to_s },
                { function: "let", parameters_as_array: false, parameters_attributes: [
                    { function: "#{ref_col.name}", parameter: "$#{ref_col.function_name}" }
                  ]
                },
                { function:  "pipeline", raw_parameter: pipeline.to_aggregation },
                { function: "as", parameter: name }
              ])
              stages << lookup

              add_field = AggregationStage.new({
                name: "$addFields", merge: false, order: 9998, arguments_attributes: [{function: "#{function_name}", parameter: "$#{name}"}]
              })
              stages << add_field

              if field.is_a?(Document::Fields::DepedencyOneField)
                unwind = AggregationStage.new(
                  name: "$unwind",
                  merge: false,
                  parameters_as_array: false,
                  order: 9998,
                  arguments_attributes: [
                    { function: "path", parameter: "$#{function_name}" },
                    { function: "preserveNullAndEmptyArrays", parameter: true }
                  ]
                )
                stages << unwind
              end

              project = AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [ {function: "#{function_name}", parameter: 1} ])
              stages << project

              stages
              #stages = [relation_field, lookup, add_field, unwind, project].compact
            end
          elsif field.nested_form
            stages = aggregation.stages
            columns.each do |column|
              stages << column.aggregation_stages
            end
          end
          stages
        end

        class << self

          def build grid, field, namespace = []
            nested = self.new(
              grid_id: grid.id,
              grid: grid,
              field_id: field.id,
              name: field.name,
              label: field.label,
              namespace: namespace,
            )
            _namespace = namespace.dup.append field.is_a?(Document::Fields::NestedFormField) ? field.name.to_s : [field.name.to_s]
            _fields = []

            if field.nested_form || field.is_a?(Document::Fields::DepedencyManyField) || field.is_a?(Document::Fields::DepedencyOneField)
              if field.nested_form
                _fields = field.nested_form.fields
              else
                _fields = field.options.form.try(:fields) || []
                # ref_col = Column.build(grid, field, namespace)
                # nested.columns << ref_col
                # if !_fields.blank? && field.options.form.is_a?(Document::Form)
                #   form = field.options.form
                #   pipeline = field.options.collection.project(id: "_id").pipeline[0] || {}
                #   if field.is_a?(Document::Fields::DepedencyManyField)
                #     pipeline["$match"].merge!({"$expr" => { "$in": [ "$$#{ref_col.function_name}", "$id" ] }})
                #   end
                #   if field.is_a?(Document::Fields::DepedencyOneField)
                #     pipeline["$match"].merge!({"$expr" => { "$eq": [ "$$#{ref_col.function_name}", "$id" ] }})
                #   end
                #   _fields.each do |f|
                #       pipeline['$project'] ||= {}
                #       pipeline['$project'][f.name] = 1
                #   end
                #   # nested.aggregation = Aggregation.new
                #   nested.aggregation.stages.build({
                #     name: "$lookup",
                #     arguments_attributes:[
                #       { function: "from" , parameter: field.options.form.collection_name},
                #       { function: "let", parameters_as_array: false, parameters_attributes: [
                #           { function: "#{ref_col.function_name}", parameter: "$#{ref_col.function_name}" }
                #         ]
                #       },
                #       { function: "as", parameter: _namespace.join(".")},
                #     ]
                #   })
                #   if field.is_a?(Document::Fields::DepedencyOneField)
                #     nested.aggregation.stages.build(
                #       name: "$unwind",
                #       parameters_as_array: false,
                #       arguments_attributes: [
                #         {function: "path", parameter: "$#{_namespace.join('.')}"},
                #         { function: "preserveNullAndEmptyArrays", parameter: true }
                #       ]
                #     )
                #   end
                #   nested.aggregation.stages.build(
                #     name: "$project",
                #     arguments_attributes: [
                #       { function: "#{_namespace.join(".")}", parameter: 1 }
                #     ]
                #   )
                # end
              end
            end

            _fields.each do |f|
              if f.nested_form.present? || f.is_a?(Document::Fields::DepedencyManyField) || f.is_a?(Document::Fields::DepedencyOneField)
                if field.is_a?(Document::Fields::DepedencyOneField) || field.is_a?(Document::Fields::DepedencyManyField)
                  nested.columns << self.build(grid, f, [])
                else
                  nested.columns << self.build(grid, f, _namespace)
                end
              else
                if field.is_a?(Document::Fields::DepedencyOneField) || field.is_a?(Document::Fields::DepedencyManyField)
                  nested.columns << Column.build(grid, f, [])
                else
                  nested.columns << Column.build(grid, f, _namespace)
                end
              end
            end

            nested
          end

        end

      end

    end
  end
end
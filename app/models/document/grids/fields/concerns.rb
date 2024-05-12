module Document
  module Grids
    module Fields
      module Concerns

        module Default

          extend ActiveSupport::Concern
          included do

            validates :field, presence: true
            # before_destroy do
            #   if default
            #     errors.add(:default, :invalid)
            #     throw :abort
            #   end
            # end

          end

          def build_default_aggregation(grid_container=nil)
            if default_aggregation
              if name
                aggregation.stages = []
                case field.type.demodulize.underscore
                when "geolocation_field"
                  aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}", parameter: 1}])
                  aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}#{field.options.location_field_suffix_name}", parameter: 1}])
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
            field.try(:type)
          end

          def field_identifier
            field.try(:identifier)
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
                position: field.position,
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

            class_attribute :valid_field_types
            self.valid_field_types = []


          end

          def valid_field
            unless self.class.valid_field_types.include?(field.type)
              errors.add(:field, :invalid)
            end
          end

          def form
            if field.attached_nested_form?
              field.nested_form
            else
              field.options.form
            end
          end

          def depedency_field?
            field.try(:depedency_field?)
          end

          def has_attached_nested_form?
            field.try(:has_attached_nested_form?)
          end

          def nested?
            true
          end

          def multiple?
            false
          end

        end

      end
    end
  end
end

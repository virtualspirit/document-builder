module Document
  module Grids
    module Fields
      module Concerns

        module Default

          extend ActiveSupport::Concern
          included do
            belongs_to :field, class_name: 'Document::Field', foreign_key: "field_id"
            belongs_to :section, class_name: "Document::Section", optional: true, foreign_key: "section_id"
            has_many :grids, class_name: "Document::Grid", foreign_key: "nested_field_id", dependent: :destroy
            has_one :grid_panel, class_name: "Document::Grids::Panel", foreign_key: "nested_field_id", dependent: :destroy
            has_one :grid_list, class_name: "Document::Grids::List", foreign_key: "nested_field_id", dependent: :destroy

            # before_save :set_section
            after_initialize :build_default_aggregation, if: Proc.new{|f| f.default_aggregation && f.persisted? }

          end

          # def set_section
          #   if grid.is_panel? && field.section_id && section.nil?
          #     self.section = grid.sections.find_by(section_id: field.section_id)
          #     if section.nil?
          #       sect = grid.append_section(field.section)
          #       sect.save
          #       self.section = sect
          #     end
          #   end
          # end


          def build_default_aggregation
            if name && aggregation
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

          def nested?
            false
          end

          def multiple?
            false
          end

          def column_names
            aggregation.stages.select{|stage| stage.name == "$project" }.map{|stage| stage.arguments.map(&:function) }.flatten 
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

            validate :valid_field, if: :field

            after_create :create_default_grids

            class_attribute :valid_field_types
            self.valid_field_types = []

            def default_grids
              grids.where(default: true, nested_field: self)
            end

            def create_default_grids
              if grid.default
                if field.depedency_field?
                  if field.type == "Document::Fields::DepedencyManyField"
                    unless grid_list
                      build_grid_list(default: true, name: field.label, form: form)
                      #grid_list.append_default_fields
                      grid_list.save
                    end
                  end
                  unless grid_panel
                    build_grid_panel(default: true, name: field.label, form: form, list: grid_list)
                   #grid_panel.append_default_fields
                    grid_panel.save
                  end
                elsif field.attached_nested_form?
                  # if field.nested_form
                    if field.type == "Document::Fields::MultipleNestedFormField"
                      unless grid_list
                        build_grid_list(default: true, name: field.label, form: form, nested_field: self)
                        #grid_list.append_default_fields
                        grid_list.save
                      end
                    end
                    unless grid_panel
                      build_grid_panel(default: true, name: field.label, form: form, nested_field: self, list: grid_list)
                      #grid_panel.append_default_fields
                      grid_panel.save
                    end
                  # end
                end
              end
            end

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

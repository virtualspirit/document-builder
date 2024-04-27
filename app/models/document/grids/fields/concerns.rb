module Document
  module Grids
    module Fields
      module Concerns

        module Default

          extend ActiveSupport::Concern
          included do
            belongs_to :field, class_name: 'Document::Field', foreign_key: "field_id"

            before_save :set_section
            before_save :build_default_aggregation, if: :default_aggregation
          end

          def set_section
            if grid.is_panel? && field.section_id && section.nil?
              self.section = grid.sections.find_by(section_id: field.section_id)
              if section.nil?
                sect = grid.append_section(field.section)
                sect.save
                self.section = sect
              end
            end
          end


          def build_default_aggregation
            if name
              aggregation.stages = []
              aggregation.stages.new(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}", parameter: 1}])
            end
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
                field_id: field.id
              )
              gf
            end

          end

        end

        module Nested

          extend ActiveSupport::Concern

          included do

            has_many :grids, class_name: "Document::Grid", foreign_key: "nested_field_id", dependent: :destroy
            has_one :grid_panel, class_name: "Document::Grids::Panel", foreign_key: "nested_field_id", dependent: :destroy
            has_one :grid_list, class_name: "Document::Grids::List", foreign_key: "nested_field_id", dependent: :destroy

            validate :valid_field, if: :field

            after_create :create_default_grids

            class_attribute :valid_field_types
            self.valid_field_types = []

            def default_grids
              grids.where(default: true, nested_field: self)
            end

            def create_default_grids
              if field.depedency_field?
                unless grid_list
                  build_grid_list(default: true, name: field.label, viewable: viewable)
                  grid_list.append_default_fields
                  grid_list.save
                end
                unless grid_panel
                  build_grid_panel(default: true, name: field.label, viewable: viewable)
                  grid_panel.append_default_fields
                  grid_panel.save
                end
              end
            end

          end

          def valid_field
            unless self.class.valid_field_types.include?(field.type)
              errors.add(:field, :invalid)
            end
          end

          def viewable
            if field.attached_nested_form?
              field.form
            else
              field.options.form
            end
          end

        end

      end
    end
  end
end
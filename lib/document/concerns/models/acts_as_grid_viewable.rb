module Document
  module Concerns
    module Models
      module ActsAsGridViewable
        extend ActiveSupport::Concern

        included  do
          has_many :grids, class_name: "Document::Grid", foreign_key: "form_id", dependent: :destroy
          has_many :grid_lists, class_name: "Document::Grids::List", foreign_key: "form_id"
          has_many :grid_panels, class_name: "Document::Grids::Panel", foreign_key: "form_id"
          has_one :default_grid_panel, -> { where(default: true, nested_field_id: nil) }, class_name: "Document::Grids::Panel", foreign_key: "form_id"
          has_one :default_grid_list, -> { where(default: true, nested_field_id: nil) }, class_name: "Document::Grids::List", foreign_key: "form_id"

          after_create :create_default_grids

        end

        def create_default_grids
          if type == "Document::Form"
            _create_default_grid_list
            _create_default_grid_panel
          end
          if type == "Document::NestedForm"
            if attachable.present?
              if attachable.type == 'Document::Fields::MultipleNestedFormField'
                _create_default_grid_list(attachable.default_grid_field)
              end
              _create_default_grid_list(attachable.default_grid_field)
            end
          end
        end

        def _create_default_grid_list(nested_field= nil)
          @list ||= grid_lists.only_default.where(nested_field: nested_field).first
          unless @list
            @list = create_default_grid_list(default: true, name: grid_title, nested_field: nested_field)
          end
          @list
        end

        def _create_default_grid_panel(nested_field= nil)
          panel = grid_panels.only_default.where(nested_field: nested_field).first
          unless panel
            panel = create_default_grid_panel(default: true, name: grid_title, nested_field: nested_field, list: default_grid_list)
          end
          panel
        end

        def grid_title
          if type == "Document::NestedForm"
            attachable.try(:label)
          else
            title
          end
        end

      end
      
    end
  end
end

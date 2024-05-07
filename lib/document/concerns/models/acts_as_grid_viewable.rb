module Document
  module Concerns
    module Models
      module ActsAsGridViewable
        extend ActiveSupport::Concern

        included  do
          has_many :grids, class_name: "Document::Grid", foreign_key: "viewable_id", dependent: :destroy
          has_many :grid_lists, class_name: "Document::Grids::List", foreign_key: "viewable_id"
          has_many :grid_panels, class_name: "Document::Grids::Panel", foreign_key: "viewable_id"

          after_create :create_default_grids, if: proc{|gv| gv.type != "Document::NestedForm" }
          after_create :attach_to_default_grids, if: proc{|gv| gv.type == "Document::NestedForm" }

        end

        def default_grids
          grids.where(default: true, container_id: nil)
        end

        def default_grid_panel
          default_grids.where(type: "Document::Grids::Panel").first
        end

        def default_grid_list
          default_grids.where(type: "Document::Grids::List").first
        end

        def create_default_grids
          # if type == "Document::NestedForm"
          #   created_default_grid_panel
          #   if attachable.type == "Document::Fields::MultipleNestedFormField"
          #     create_default_grid_list
          #   end
          # end
          create_default_grid_list
          create_default_grid_panel
        end

        def create_default_grid_list
          @list ||= grid_lists.where(default: true).first
          unless @list
            @list = grid_lists.create(default: true, name: grid_title)#, nested_field: type == "Document::NestedForm" ? attachable : nil)
          end
          @list
        end

        def create_default_grid_panel
          panel = grid_panels.where(default: true).first
          unless panel
            grid_panels.create(default: true, name: grid_title, list: create_default_grid_list)#, nested_field: type == "Document::NestedForm" ? attachable : nil)
          end
        end

        def attach_to_default_grids
          if type == "Document::NestedForm"
            if attachable
              Grid.where(nested_field_id: attachable.grid_fields.pluck(:id)).update_all(viewable_id: self.id)
            end
          end
        end

        def grid_title
          if type == "Document::NestedForm"
            attachable.label
          else
            title
          end
        end

      end
      # module ActsAsGridViewable
      #   extend ActiveSupport::Concern

      #   included  do
      #     has_many :grids, class_name: "Document::Grid", as: :viewable, dependent: :destroy
      #     has_many :grid_lists, class_name: "Document::Grids::List", as: :viewable
      #     has_many :grid_panels, class_name: "Document::Grids::Panel", as: :viewable

      #     after_create :create_default_grids

      #   end

      #   def default_grids
      #     grids.where(default: true, nested_field: nil)
      #   end

      #   def create_default_grids
      #     create_default_grid_list
      #     create_default_grid_panel
      #   end

      #   def create_default_grid_list
      #     list = grid_lists.where(default: true).first
      #     unless list
      #       grid_lists.create(default: true, name: grid_title, nested_field: type == "Document::NestedForm" ? attachable : nil)
      #     end
      #   end

      #   def create_default_grid_panel
      #     panel = grid_panels.where(default: true).first
      #     unless panel
      #       grid_panels.create(default: true, name: grid_title, nested_field: type == "Document::NestedForm" ? attachable : nil)
      #     end
      #   end

      #   def grid_title
      #     title
      #   end

      #   def to_virtual_view
      #     raise ArgumentError, "#{self} must return a #{::Document::VirtualModel}'s subclass"
      #   end

      # end
    end
  end
end

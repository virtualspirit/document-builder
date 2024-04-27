module Document
  module Concerns
    module Models
      module ActsAsGridViewable
        extend ActiveSupport::Concern

        included  do
          has_many :grids, class_name: "Document::Grid", as: :viewable, dependent: :destroy
          has_many :grid_lists, class_name: "Document::Grids::List", as: :viewable
          has_many :grid_panels, class_name: "Document::Grids::Panel", as: :viewable

          after_create :create_default_grids

        end

        def default_grids
          grids.where(default: true, nested_field: nil)
        end

        def create_default_grids
          create_default_grid_list
          create_default_grid_panel
        end

        def create_default_grid_list
          list = grid_lists.where(default: true).first
          unless list
            grid_lists.create(default: true, name: grid_title, nested_field: type == "Document::NestedForm" ? attachable : nil)
          end
        end

        def create_default_grid_panel
          panel = grid_panels.where(default: true).first
          unless panel
            grid_panels.create(default: true, name: grid_title, nested_field: type == "Document::NestedForm" ? attachable : nil)
          end
        end

        def grid_title
          title
        end

        def to_virtual_view
          raise ArgumentError, "#{self} must return a #{::Document::VirtualModel}'s subclass"
        end

      end
    end
  end
end

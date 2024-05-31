module Document
  module Grids
    class GridField < ApplicationRecord

      self.table_name = 'document_grids_fields'

      belongs_to :field, class_name: "Document::Grids::Field", foreign_key: "field_id", inverse_of: :grid_fields, touch: true
      belongs_to :grid, class_name: "Document::Grid", foreign_key: "grid_id", inverse_of: :grid_fields, touch: true

      validates :grid_id, uniqueness: { scope: :field_id }

      positioned on: :grid, column: :field_position_on_grid

      after_validation :set_position, on: :create

      attr_accessor :position

      after_save do
        if saved_change_to_field_position_on_grid?
          invalidate_cached_field_position_on_grid
          self.class.includes(:field).where(grid_id: grid_id).each(&:invalidate_cached_field_position_on_grid)
        end
      end

      def invalidate_cached_field_position_on_grid
        field.invalidate_cache_of_cached_position_on_grid
      end

      def position=(val)
        @position = val
        self.field_position_on_grid= val
      end

      def set_position
        if field && field.set_position_on_grid
          self.position= field.set_position_on_grid
        else
          self.position= :last
        end
      end


    end
  end
end
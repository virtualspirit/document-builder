module Document
  module Grids
    class GridField < ApplicationRecord

      self.table_name = 'document_grids_fields'

      belongs_to :field, class_name: "Document::Grids::Field", foreign_key: "field_id", inverse_of: :grid_fields
      belongs_to :grid, class_name: "Document::Grid", foreign_key: "grid_id", inverse_of: :grid_fields

      validates :grid_id, uniqueness: { scope: :field_id }

      after_validation :set_position, on: :create

      include RankedModel
      ranks :field_position_on_grid, with_same: :grid_id

      attr_accessor :position

      def position=(val)
        @position = val
        self.field_position_on_grid_position=(val)
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
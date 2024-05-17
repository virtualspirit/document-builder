module Document
  module Grids
    class GridNestedField < ApplicationRecord

      self.table_name = 'document_grids_nested_fields'

      belongs_to :nested_field, class_name: "Document::Grids::Field", foreign_key: "nested_field_id"
      belongs_to :nested_grid, class_name: "Document::Grid", foreign_key: "nested_grid_id"

      validates :nested_grid_id, uniqueness: { scope: :nested_field_id }

      before_save do
        self.grid_type= nested_grid.try(:type)
      end

      validate do
        unless nested_field.nested?
          errors.add(:nested_field, :invalid)
        end
      end

    end
  end
end
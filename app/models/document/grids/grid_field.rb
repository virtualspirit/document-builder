module Document
  module Grids
    class GridField < ApplicationRecord

      self.table_name = 'document_grids_fields'

      belongs_to :field, class_name: "Document::Grids::Field", foreign_key: "field_id", inverse_of: :grid_fields
      belongs_to :grid, class_name: "Document::Grid", foreign_key: "grid_id", inverse_of: :grid_fields

      validates :grid_id, uniqueness: { scope: :field_id }

    end
  end
end
# create_table :document_grid_columns do |t|
#   t.references :field
#   t.references :nested_column
#   t.references :grid
#   t.string :name
#   t.string :label
#   t.string :namespace
#   t.integer :order
#   t.string :type
#   t.text :aggregation
#   t.timestamps
# end

module Document
  module Grids
    class Field < ApplicationRecord

      include Fields::Concerns::Buildable

      self.table_name = 'document_grid_fields'

      belongs_to :grid, class_name: 'Document::Grid'

      include RankedModel
      ranks :position, with_same: [:section_id, :grid_id], class_name: self.name

      serialize :namespace, Array
      serialize :aggregation, Document::Grids::Aggregation

      delegate :to_aggregation, to: :aggregation

      def aggregation_stages
        aggregation.try(:stages) || []
      end

      def function_name
        (namespace || []).dup.append(name).join(".")
      end

    end
  end
end
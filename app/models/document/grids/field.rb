# create_table :document_grid_columns do |t|
#   t.references :field
#   t.references :nested_column
#   t.references :grid
#   t.string :name
#   t.string :label
#   t.string :namespace
#   t.integer :order
#   t.string :type
#   t.boolean :default_aggregation
#   t.boolean :default
#   t.text :aggregation
#   t.timestamps
# end

module Document
  module Grids
    class Field < ApplicationRecord

      include Fields::Concerns::Buildable

      scope :only_default, -> { where(default: true) }

      self.table_name = 'document_grid_fields'

      #belongs_to :grid, class_name: 'Document::Grid'
      has_many :grid_fields, class_name: "Document::Grids::GridField", foreign_key: "field_id", dependent: :destroy
      has_many :grids, through: :grid_fields

      include RankedModel
      ranks :position, with_same: [:section_id, :grid_id], class_name: self.name

      serialize :namespace, Array
      serialize :aggregation, Document::Grids::Aggregation

      delegate :to_aggregation, to: :aggregation

      validates :default_aggregation, acceptance: true, if: :default

      def aggregation_stages
        aggregation.try(:stages) || []
      end

      def function_name
        (namespace || []).dup.append(name).join(".")
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

      def build_default_aggregation
        aggregation
      end

      class << self

        def timestamp_fields
          [Document::Grids::Fields::AggregateColumn.created_at, Document::Grids::Fields::AggregateColumn.updated_at]
        end

      end

    end
  end
end
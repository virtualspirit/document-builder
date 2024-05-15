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

      belongs_to :field, class_name: 'Document::Field', foreign_key: "field_id", optional: true
      belongs_to :section, class_name: "Document::Section", optional: true, foreign_key: "section_id"
      has_many :grid_fields, class_name: "Document::Grids::GridField", foreign_key: "field_id", dependent: :destroy, inverse_of: :field
      has_many :grids, through: :grid_fields
      has_many :grid_panels, lambda { where(type: "Document::Grids::Panel") }, through: :grid_fields, source: :grid
      has_many :grid_lists, lambda { where(type: "Document::Grids::List") }, through: :grid_fields, source: :grid
      has_many :grid_nested_fields, class_name: "Document::Grids::GridNestedField", foreign_key: "nested_field_id", dependent: :destroy
      has_many :nested_grids, through: :grid_nested_fields, class_name: "Document::Grid"
      has_one :grid_list_nested_field, -> { where(grid_type: "Document::Grids::List") }, class_name: "Document::Grids::GridNestedField", foreign_key: "nested_field_id"
      has_one :nested_grid_list, through: :grid_list_nested_field, source: :nested_grid
      has_one :grid_panel_nested_field, -> { where(grid_type: "Document::Grids::Panel") }, class_name: "Document::Grids::GridNestedField", foreign_key: "nested_field_id"
      has_one :nested_grid_panel, through: :grid_panel_nested_field, source: :nested_grid

      include RankedModel
      ranks :position, with_same: [:section_id, :grid_id], class_name: self.name

      serialize :namespace, Array
      serialize :aggregation, Document::Grids::Aggregation

      delegate :to_aggregation, to: :aggregation

      validates :default_aggregation, acceptance: true, if: :default

      validate do
        unless type_was.nil?
          if type_was != type
            errors.add(:type, :invalid)
          end
        end
      end

      validate do
        unless aggregation.valid?
          errors.add(:aggregation, :invalid)
          aggregation.errors.each {|e| errors.import e, **e.options.merge(attribute: "aggregation.#{e.attribute}")}
        end
      end

      def set_as_default
        update(default: true)
      end

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

      def column_names(grid_container = nil)
        if grid_container
          build_default_aggregation(grid_container)
        end
        aggregation.stages.select{|stage| stage.name == "$project" }.map{|stage| stage.arguments.map(&:function) }.flatten
      end

      def build_default_aggregation(grid_container=nil)
        aggregation
      end

      def field_type
        nil
      end

      def field_identifier
        nil
      end

      class << self

        def timestamp_fields
          [Document::Grids::Fields::AggregateColumn.created_at, Document::Grids::Fields::AggregateColumn.updated_at]
        end

      end

    end
  end
end
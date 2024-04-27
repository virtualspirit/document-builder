# create_table :document_grid_sections do |t|
#   t.string :title, default: ""
#   t.text :description
#   t.boolean :headless, null: false, default: false
#   t.belongs_to :grid
#   t.belongs_to :section
#   t.integer :position
#   t.timestamps
# end

module Document
  module Grids
    class Section < ApplicationRecord

      self.table_name = 'document_grid_sections'

      belongs_to :grid, class_name: 'Document::Grid', foreign_key: "grid_id"
      belongs_to :panel, class_name: "Document::Grids::Panel", foreign_key: "grid_id"
      belongs_to :section, class_name: "Document::Section"

      has_many :fields, -> { rank(:position) }, class_name: "Document::Grids::Field", dependent: :destroy, index_errors: true
      accepts_nested_attributes_for :fields, allow_destroy: true

      include RankedModel
      ranks :position, with_same: [:grid_id]

      validates :title, presence: true, uniqueness: { scope: [:grid_id], allow_nil: true }, unless: :headless
      before_save do
        self.headless ||= false
      end

    end
  end
end
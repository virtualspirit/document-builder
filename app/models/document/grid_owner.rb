# create_table :document_grid_owners do |t|
#   t.references :owner, polymorphic: true
#   t.references :grid
#   t.timestamps
# end

module Document
  class GridOwner < ApplicationRecord

    belongs_to :owner, polymorphic: true, optional: true
    belongs_to :grid, class_name: "Document::Grid", foreign_key: "grid_id"
    # has_one :query_builder, class_name: "Document::QuerBuilder", as: :context

    validates :grid_id, :uniqueness => { scope: [:owner_type, :owner_id] }

  end
end
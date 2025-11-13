# create_table :document_grid_owners do |t|
#   t.references :owner, polymorphic: true
#   t.references :grid
#   t.timestamps
# end

module Document
  class GridOwner < ApplicationRecord

    belongs_to :owner, polymorphic: true
    belongs_to :grid, class_name: "Document::Grid"

  end
end
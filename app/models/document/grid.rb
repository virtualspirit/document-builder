# create_table :document_grids do |t|
#   t.references :viewable, polymorphic: true
#   t.string :name
#   t.text :options
#   t.integer :order
#   t.string :type
#   t.text :configuration
#   t.boolean :default, default: false
#   t.timestamps
# end

module Document
  class Grid < ApplicationRecord

    belongs_to :viewable, polymorphic: true
    has_many :fields, class_name: "Document::Grids::Field", foreign_key: "grid_id"
    accepts_nested_attributes_for :fields, allow_destroy: true

    validates :name, presence: true
    validates :type, presence: true, inclusion: { in: ['Document::Grids::Table', 'Document::Grids::Panel'] }

    def draw fields_collection = viewable.try(:fields) || [], _fields = []
      fields_collection.each do |field|
        if field.nested_form.present? || field.is_a?(Document::Fields::DepedencyManyField) || field.is_a?(Document::Fields::DepedencyOneField)
          _fields << Document::Grids::Field::NestedColumn.build(self, field)
        else
          _fields << Document::Grids::Field::Column.build(self, field)
        end
      end
      _fields
    end

    def virtual_view
      if viewable
        @virtual_view ||= viewable.to_virtual_view
      end
    end

    def virtual_view!
      if viewable
        @virtual_view = viewable.to_virtual_view
      end
    end

  end
end
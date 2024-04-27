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

# module Document
#   class Grid < ApplicationRecord

#     belongs_to :viewable, polymorphic: true
#     has_many :fields, class_name: "Document::Grids::Field", foreign_key: "grid_id", dependent: :destroy
#     accepts_nested_attributes_for :fields, allow_destroy: true

#     validates :name, presence: true
#     validates :type, presence: true, inclusion: { in: ['Document::Grids::List', 'Document::Grids::Panel'] }

#     def draw fields_collection = viewable.try(:fields) || [], namespace = []
#       fields_collection.each do |field|
#         self.fields << Document::Grids::Field.build(self, field, namespace)
#       end
#       self.fields
#     end

#     def virtual_view
#       if viewable
#         @virtual_view ||= viewable.to_virtual_view
#       end
#     end

#     def virtual_view!
#       if viewable
#         @virtual_view = viewable.to_virtual_view
#       end
#     end

#   end
# end

module Document
  class Grid < ApplicationRecord

    belongs_to :viewable, polymorphic: true
    belongs_to :nested_field, class_name: "Document::Grids::Field", foreign_key: "nested_field_id", optional: true
    has_many :fields, -> { rank(:position) }, class_name: "Document::Grids::Field", dependent: :destroy, foreign_key: "grid_id", inverse_of: :grid, index_errors: true

    accepts_nested_attributes_for :fields, allow_destroy: true

    validates :name, presence: true
    validates :viewable, presence: true

    validate do
      if viewable
        unless viewable.class.included_modules.include?(Document::Concerns::Models::ActsAsGridViewable)
          errors.add(:viewable, :invalid)
        end
      end
    end

    before_create :append_default_fields

    def virtual_view
      if viewable
        @virtual_view ||= viewable.to_virtual_view
      end
    end

    def is_panel?
      false
    end

    def is_list?
      false
    end

    def add_field field, namespace: [], persist: true
      gf = ::Document::Grids::Field.build(field, namespace)
      gf.grid = self
      gf.save if persist
      gf
    end

    def append_default_fields
      append_fields(viewable.fields)
    end

    def append_fields _fields = []
      self.fields << _fields.map{|f| add_field(f, persist: false) }
    end

  end
end
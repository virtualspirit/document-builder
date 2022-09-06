class CreateFields < ActiveRecord::Migration[6.1]
  def change
    create_table :document_fields do |t|
      t.string :name, null: false
      t.string :label, default: ""
      t.string :hint, default: ""
      t.integer :accessibility, null: false
      t.text :options
      t.text :validations
      t.integer :position
      t.string :type
      t.belongs_to :form, index: true
      t.belongs_to :section, index: true
      t.belongs_to :field_group, index: true
      t.timestamps
    end
  end
end

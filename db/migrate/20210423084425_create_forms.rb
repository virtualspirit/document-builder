class CreateForms < ActiveRecord::Migration[6.1]
  def change
    create_table :document_forms do |t|
      t.string :name
      t.string :title
      t.text :description
      t.string :type, null: false, index: true
      t.string :code
      t.references :attachable, polymorphic: true, index: true
      t.timestamps
    end
  end
end

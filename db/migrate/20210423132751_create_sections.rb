class CreateSections < ActiveRecord::Migration[6.1]
  def change
    create_table :document_sections do |t|
      t.string :title, default: ""
      t.text :description
      t.boolean :headless, null: false, default: false
      t.belongs_to :form
      t.integer :position

      t.timestamps
    end
  end
end

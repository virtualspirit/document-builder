class CreateFieldGroup < ActiveRecord::Migration[6.1]
  def change
    create_table :field_groups do |t|
      t.string :name, default: ""
      t.timestamps
    end
  end
end

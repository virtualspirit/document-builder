class AddStepOptions < ActiveRecord::Migration[6.1]
  def change
    add_column :document_forms, :step, :boolean
    add_column :document_forms, :step_options, :text
  end
end

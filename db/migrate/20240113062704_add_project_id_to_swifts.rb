class AddProjectIdToSwifts < ActiveRecord::Migration[7.0]
  def change
      add_column :swifts, :project_id, :integer
      change_column_null :swifts, :project_id, true
      add_index :swifts, :project_id
  end
end

class AddProjectNumberToSwifts < ActiveRecord::Migration[7.0]
  def change
    add_column :swifts, :project_number, :string
  end
end

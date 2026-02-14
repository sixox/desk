class AddCompletionFlagsToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :sales_done, :boolean, default: false, null: false
    add_column :projects, :logistics_done, :boolean, default: false, null: false

    add_index :projects, :sales_done
    add_index :projects, :logistics_done
  end
end

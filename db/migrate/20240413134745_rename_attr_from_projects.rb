class RenameAttrFromProjects < ActiveRecord::Migration[7.0]
  def change
    rename_column :projects, :attr, :selected_risk
  end
end

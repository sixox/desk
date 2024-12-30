class AddReleasePermissionToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :release_permission, :boolean
  end
end

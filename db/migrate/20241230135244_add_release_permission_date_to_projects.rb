class AddReleasePermissionDateToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :release_permission_date, :date
  end
end

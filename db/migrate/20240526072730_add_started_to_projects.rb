class AddStartedToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :started, :boolean
  end
end

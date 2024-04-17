class AddRiskToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :risk, :boolean
  end
end

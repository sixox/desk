class ChangeRiskToIntegerInProjects < ActiveRecord::Migration[7.0]
  def change
    change_column :projects, :risk, :integer
  end
end

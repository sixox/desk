class AddImpactAndLikelihoodToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :impact, :integer
    add_column :projects, :likelihood, :integer
  end
end

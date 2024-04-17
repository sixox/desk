class AddBooleanAttributesToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :new_destination, :boolean
    add_column :projects, :shipping, :boolean
    add_column :projects, :exchange, :boolean
    add_column :projects, :supplier_prepaid, :boolean
    add_column :projects, :delivery_failure, :boolean
    add_column :projects, :supplier_credits, :boolean
    add_column :projects, :third_person, :boolean
    add_column :projects, :account, :boolean
    add_column :projects, :logistic, :boolean
    add_column :projects, :quality, :boolean
  end
end

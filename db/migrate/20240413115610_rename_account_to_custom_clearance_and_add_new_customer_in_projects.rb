class RenameAccountToCustomClearanceAndAddNewCustomerInProjects < ActiveRecord::Migration[7.0]
  def change
    rename_column :projects, :account, :custom_clearance
    add_column :projects, :new_customer, :boolean, default: false
  end
end

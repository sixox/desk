class AddUserToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_reference :customers, :user, index: true
  end
end

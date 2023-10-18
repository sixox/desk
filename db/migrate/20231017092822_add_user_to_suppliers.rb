class AddUserToSuppliers < ActiveRecord::Migration[7.0]
  def change
    add_reference :suppliers, :user, null: false, foreign_key: true
  end
end

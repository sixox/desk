class RenameIsSecretToMahramane < ActiveRecord::Migration[7.0]
  def change
    remove_column :payment_orders, :is_secret, :boolean
    add_column :payment_orders, :mahramane, :boolean, default: false
  end
end

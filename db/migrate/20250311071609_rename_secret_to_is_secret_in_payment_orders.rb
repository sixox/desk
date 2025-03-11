class RenameSecretToIsSecretInPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    rename_column :payment_orders, :secret, :is_secret
  end
end

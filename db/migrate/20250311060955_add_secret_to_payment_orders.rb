class AddSecretToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :secret, :boolean
  end
end

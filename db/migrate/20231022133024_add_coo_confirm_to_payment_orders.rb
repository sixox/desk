class AddCooConfirmToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :coo_confirm, :boolean
  end
end

class AddDeliveryConfirmToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :delivery_confirm, :boolean
  end
end

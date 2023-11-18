class AddDeliveredConfirmationDateToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :delivered_at, :datetime
  end
end

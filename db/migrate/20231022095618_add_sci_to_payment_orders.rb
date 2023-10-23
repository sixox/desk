class AddSciToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_reference :payment_orders, :sci, null: false, foreign_key: true
  end
end

class AddAnnounceToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :announce, :boolean, default: false, null: false
  end
end

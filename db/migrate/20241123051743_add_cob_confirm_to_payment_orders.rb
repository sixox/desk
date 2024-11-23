class AddCobConfirmToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :cob_confirm, :boolean, default: false
    add_column :payment_orders, :cob_confirmed_at, :datetime
  end
end

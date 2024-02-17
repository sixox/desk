class AddHamedConfirmToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :hamed_confirm, :boolean
    add_column :payment_orders, :hamed_confirmed_at, :datetime
  end
end

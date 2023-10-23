class AddIsRahkarsazanToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :is_rahkarsazan, :boolean
  end
end

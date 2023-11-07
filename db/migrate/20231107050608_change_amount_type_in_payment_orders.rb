class ChangeAmountTypeInPaymentOrders < ActiveRecord::Migration[7.0]
  def change
        change_column :payment_orders, :amount, :bigint
  end
end

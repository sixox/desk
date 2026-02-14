class AddCostTypeToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :cost_type, :string
    add_index  :payment_orders, :cost_type
  end
end

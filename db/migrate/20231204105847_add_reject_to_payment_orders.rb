class AddRejectToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :reject_by, :string
    add_column :payment_orders, :rejected_at, :datetime
  end
end

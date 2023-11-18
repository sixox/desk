class AddConfirmationDateToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :ceo_confirmed_at, :datetime
    add_column :payment_orders, :coo_confirmed_at, :datetime
    add_column :payment_orders, :department_confirmed_at, :datetime
    add_column :payment_orders, :accounting_confirmed_at, :datetime
  end
end

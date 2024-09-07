class AddShaghayeghConfirmToPaymentOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_orders, :shaghayegh_confirm, :boolean
  end
end

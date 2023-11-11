class AddPaymentIdToNotifications < ActiveRecord::Migration[7.0]
  def change
    add_column :notifications, :payment_id, :integer
  end
end

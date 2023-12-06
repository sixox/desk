class AddIndexOnStatus < ActiveRecord::Migration[7.0]
  def change
    add_index :payment_orders, :status

  end
end

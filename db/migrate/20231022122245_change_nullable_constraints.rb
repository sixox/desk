class ChangeNullableConstraints < ActiveRecord::Migration[7.0]
  def change
    change_column :payment_orders, :project_id, :bigint, null: true
    change_column :payment_orders, :sci_id, :integer, null: true
    change_column :payment_orders, :spi_id, :integer, null: true
    change_column :payment_orders, :ballance_id, :integer, null: true
    change_column :payment_orders, :booking_id, :integer, null: true
  end
end

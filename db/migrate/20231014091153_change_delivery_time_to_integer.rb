class ChangeDeliveryTimeToInteger < ActiveRecord::Migration[7.0]
  def change
    change_column :pis, :delivery_time, :integer
  end
end

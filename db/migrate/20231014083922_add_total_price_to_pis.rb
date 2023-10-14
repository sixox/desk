class AddTotalPriceToPis < ActiveRecord::Migration[7.0]
  def change
    add_column :pis, :total_price, :float
  end
end

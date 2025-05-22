class AddSalesByToPis < ActiveRecord::Migration[7.0]
  def change
    add_column :pis, :sales_by, :string
  end
end

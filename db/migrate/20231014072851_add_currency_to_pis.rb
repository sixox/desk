class AddCurrencyToPis < ActiveRecord::Migration[7.0]
  def change
    add_column :pis, :currency, :string
  end
end

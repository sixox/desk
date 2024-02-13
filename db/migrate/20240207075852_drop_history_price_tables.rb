class DropHistoryPriceTables < ActiveRecord::Migration[7.0]
  def change
    drop_table :history_price_tables
  end
end

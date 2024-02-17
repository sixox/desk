class AddRefineryToHistoricalPrices < ActiveRecord::Migration[7.0]
  def change
    add_column :historical_prices, :refinery, :string
  end
end

class CreateHistoryPriceTable < ActiveRecord::Migration[7.0]
  def change
    create_table :history_price_tables do |t|
      t.string :quantity
      t.string :purchase_price
      t.string :fob_cost
      t.string :fob_price
      t.datetime :time
      t.references :price, null: false, foreign_key: true

      t.timestamps
    end
  end
end

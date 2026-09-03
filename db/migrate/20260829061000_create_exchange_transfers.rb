class CreateExchangeTransfers < ActiveRecord::Migration[7.0]
  def change
    create_table :exchange_transfers do |t|
      t.references :exchange, null: false, foreign_key: true
      t.references :xtransfer, null: false, foreign_key: true

      t.timestamps
    end
  end
end

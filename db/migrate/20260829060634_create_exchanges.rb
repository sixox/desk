class CreateExchanges < ActiveRecord::Migration[7.0]
  def change
    create_table :exchanges do |t|
      t.references :seller_account,
                   null: false,
                   foreign_key: { to_table: :xaccounts }

      t.references :buyer_account,
                   null: false,
                   foreign_key: { to_table: :xaccounts }

      t.references :sell_currency,
                   null: false,
                   foreign_key: { to_table: :currencies }

      t.references :buy_currency,
                   null: false,
                   foreign_key: { to_table: :currencies }

      t.float :exchange_rate

      t.bigint :sell_amount
      t.bigint :buy_amount
      t.float :wage
      t.boolean :pending, null: false, default: false
      t.datetime :pending_set_time
      t.integer :kind, null: false, default: 0

      t.timestamps
    end
  end
end
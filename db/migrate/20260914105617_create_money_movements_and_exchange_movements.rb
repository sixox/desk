class CreateMoneyMovementsAndExchangeMovements < ActiveRecord::Migration[7.0]
  def change
    create_table :money_movements do |t|
      # send / receive
      t.string :direction, null: false

      # Account and its currency
      t.integer :xaccount_id, null: false
      t.integer :currency_id, null: false

      # Original amount
      t.bigint :amount, null: false, default: 0

      # Optional conversion
      t.float :exchange_rate
      t.integer :to_currency_id
      t.bigint :amount_to

      # Charge and final amount
      t.bigint :charge, null: false, default: 0
      t.bigint :total, null: false, default: 0

      # Xtransfer / Xpayment / Remittance
      t.string :movable_type, null: false
      t.integer :movable_id, null: false

      t.timestamps
    end

    add_index :money_movements, :direction
    add_index :money_movements, :xaccount_id
    add_index :money_movements, :currency_id
    add_index :money_movements, :to_currency_id

    add_index :money_movements,
    [:movable_type, :movable_id],
    name: "index_money_movements_on_movable"

    create_table :exchange_movements do |t|
      # sell / buy
      t.string :direction, null: false

      # Account and its currency
      t.integer :xaccount_id, null: false
      t.integer :currency_id, null: false

      # Original amount
      t.bigint :amount, null: false, default: 0

      # Optional conversion
      t.float :exchange_rate
      t.integer :to_currency_id
      t.bigint :amount_to

      # Charge and final amount
      t.bigint :charge, null: false, default: 0
      t.bigint :total, null: false, default: 0

      # Parent Exchange
      t.integer :exchange_id, null: false

      t.timestamps
    end

    add_index :exchange_movements, :direction
    add_index :exchange_movements, :xaccount_id
    add_index :exchange_movements, :currency_id
    add_index :exchange_movements, :to_currency_id
    add_index :exchange_movements, :exchange_id
  end
end

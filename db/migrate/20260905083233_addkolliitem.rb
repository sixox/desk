class Addkolliitem < ActiveRecord::Migration[7.0]
  def change
    drop_table :credits
    add_column :xaccounts, :amount, :bigint, default: 0, null: false
    create_table :xtransactions do |t|
      t.bigint :deposit_amount
      t.bigint :withdrawal_amount
      t.bigint :balance_before_transaction
      t.bigint :balance_after_transaction


      t.references :transactionable, polymorphic: true, null: false
      t.references :xaccount, null: false, foreign_key: true
      t.references :currency, null: false, foreign_key: true

      t.timestamps
    end

  end
end

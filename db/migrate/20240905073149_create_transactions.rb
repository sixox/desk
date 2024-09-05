class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.bigint :deposit_amount
      t.bigint :withdrawal_amount
      t.bigint :balance_before_transaction
      t.bigint :balance_after_transaction
      t.references :transactionable, polymorphic: true, null: false
      t.references :bank, null: false, foreign_key: true

      t.timestamps
    end
  end
end

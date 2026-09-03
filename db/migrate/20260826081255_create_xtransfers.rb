class CreateXtransfers < ActiveRecord::Migration[7.0]
  def change
    create_table :xtransfers do |t|
      t.bigint :sent_amount
      t.bigint :receive_amount
      t.float :exchange_rate
      t.integer :wage
      t.references :sender_account, null: false, foreign_key: { to_table: :xaccounts }
      t.references :receiver_account, null: false, foreign_key: { to_table: :xaccounts }
      t.string :status
      t.boolean :pending, null: false, default: false
      t.datetime :pending_set_time

      t.timestamps
    end
  end
end

class CreateRemittances < ActiveRecord::Migration[7.0]
  def change
    create_table :remittances do |t|
      t.references :sender_account,
                   null: false,
                   foreign_key: { to_table: :xaccounts }

      t.references :receiver_account,
                   null: false,
                   foreign_key: { to_table: :xaccounts }

      t.bigint :sent_amount, null: false
      t.bigint :received_amount, null: false

      t.references :currency,
                   null: false,
                   foreign_key: true

      t.timestamps
    end
  end
end
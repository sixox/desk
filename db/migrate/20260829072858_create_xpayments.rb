class CreateXpayments < ActiveRecord::Migration[7.0]
  def change
    create_table :xpayments do |t|
      t.references :sender_account,
                   null: false,
                   foreign_key: { to_table: :xaccounts }

      t.references :receiver_account,
                   null: false,
                   foreign_key: { to_table: :xaccounts }

      t.references :currency,
                   null: false,
                   foreign_key: true

      t.float :wage

      t.timestamps
    end
  end
end
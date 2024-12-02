class CreateRialReceipts < ActiveRecord::Migration[7.0]
  def change
    create_table :rial_receipts do |t|
      t.references :payment_order, null: false, foreign_key: true
      t.text :in_words
      t.text :details
      t.string :receiver
      t.string :account_number
      t.string :check_number
      t.string :check_bank
      t.date :check_date
      t.string :check_account
      t.string :from_source
      t.date :payment_date

      t.timestamps
    end
  end
end

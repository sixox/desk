class CreatePaymentOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_orders do |t|
      t.string :reference
      t.integer :amount
      t.string :from
      t.string :to
      t.string :receiver
      t.string :receiver_account
      t.text :details
      t.float :exchange_rate
      t.float :exchange_amount
      t.boolean :have_factor
      t.boolean :inserted
      t.string :payment_type
      t.boolean :department_confirm
      t.boolean :accounting_confirm
      t.boolean :ceo_confirm
      t.string :status
      t.string :currency
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class CreateScis < ActiveRecord::Migration[7.0]
  def change
    create_table :scis do |t|
      t.references :spi, null: false, foreign_key: true
      t.float :net_weight
      t.float :gross_weight
      t.float :total_price
      t.float :advance_payment
      t.float :balance_payment
      t.string :bank_account
      t.date :issue_date
      t.boolean :have_loading_report
      t.string :status

      t.timestamps
    end
  end
end

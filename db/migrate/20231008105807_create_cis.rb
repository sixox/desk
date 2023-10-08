class CreateCis < ActiveRecord::Migration[7.0]
  def change
    create_table :cis do |t|
      t.references :pi, foreign_key: true
      t.float :net_weight
      t.float :gross_weight
      t.float :total_price
      t.float :advance_payment
      t.float :balance_payment
      t.string :bank_account
      t.date :issue_date
      t.references :project, foreign_key: true

      t.timestamps
    end
  end
end

class CreateSpis < ActiveRecord::Migration[7.0]
  def change
    create_table :spis do |t|
      t.string :number
      t.string :product
      t.integer :validity
      t.references :user, null: false, foreign_key: true
      t.float :quantity
      t.float :unit_price
      t.string :payment_term
      t.string :bank_account
      t.string :packing_type
      t.integer :packing_count
      t.string :supplier
      t.string :seller
      t.date :issue_date
      t.string :term
      t.references :ballance, null: false, foreign_key: true
      t.float :total_price

      t.timestamps
    end
  end
end

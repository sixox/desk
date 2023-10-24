class CreatePis < ActiveRecord::Migration[7.0]
  def change
    create_table :pis do |t|
      t.string :number
      t.string :product
      t.integer :validity
      t.float :quantity
      t.float :unit_price
      t.string :payment_term
      t.string :bank_account
      t.string :packing_type
      t.integer :packing_count
      t.float :shipment_rate
      t.string :seller
      t.date :delivery_time
      t.date :issue_date
      t.string :pol
      t.string :pod
      t.references :customer, null: false, foreign_key: true

      t.timestamps
    end
  end
end

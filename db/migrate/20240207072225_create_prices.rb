class CreatePrices < ActiveRecord::Migration[7.0]
  def change
    create_table :prices do |t|
      t.string :name
      t.string :packing
      t.string :oil_content
      t.string :refinery
      t.string :quantity
      t.string :purchase_price
      t.string :fob_cost
      t.string :fob_price
      t.string :description
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

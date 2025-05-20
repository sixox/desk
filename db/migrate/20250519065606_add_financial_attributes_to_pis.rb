class AddFinancialAttributesToPis < ActiveRecord::Migration[7.0]
  def change
    change_table :pis do |t|
      t.integer :cttd
      t.integer :purchase
      t.integer :freight
      t.integer :transport
      t.integer :packing_cost
      t.integer :custom_cost
      t.integer :internal_commission
      t.integer :foreign_commission
      t.integer :other_cost
      t.integer :predict_profit
      t.integer :insurance
      t.integer :inspection
      t.boolean :rejected
      t.boolean :confirmed
      t.date :confirm_or_reject_time
    end
  end
end

class CreateDeposits < ActiveRecord::Migration[7.0]
  def change
    create_table :deposits do |t|
      t.references :bank, null: false, foreign_key: true
      t.integer :amount
      t.text :details

      t.timestamps
    end
  end
end

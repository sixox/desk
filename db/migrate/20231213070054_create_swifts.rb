class CreateSwifts < ActiveRecord::Migration[7.0]
  def change
    create_table :swifts do |t|
      t.integer :amount
      t.references :bank, null: false, foreign_key: true
      t.string :status
      t.boolean :confirmed
      t.boolean :rejected
      t.datetime :confirm_at
      t.datetime :rejected_at

      t.timestamps
    end
  end
end

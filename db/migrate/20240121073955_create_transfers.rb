class CreateTransfers < ActiveRecord::Migration[7.0]
  def change
    create_table :transfers do |t|
      t.integer :withdraw_from
      t.integer :withdraw_amount
      t.integer :deposited_to
      t.integer :deposited_amount
      t.decimal :wage

      t.timestamps
    end
  end
end

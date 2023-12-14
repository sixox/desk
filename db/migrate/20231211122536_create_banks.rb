class CreateBanks < ActiveRecord::Migration[7.0]
  def change
    create_table :banks do |t|
      t.string :name
      t.boolean :type
      t.string :currency
      t.bigint :account_balance
      t.bigint :checked_balance

      t.timestamps
    end
  end
end

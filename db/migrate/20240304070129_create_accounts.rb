class CreateAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :accounts do |t|
      t.string :name
      t.text :details
      t.references :bank, null: false, foreign_key: true

      t.timestamps
    end
  end
end

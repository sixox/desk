class CreateXaccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :xaccounts do |t|
      t.text :number
      t.references :currency, null: false, foreign_key: true
      t.string :kind
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end

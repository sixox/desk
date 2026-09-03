class CreateCredits < ActiveRecord::Migration[7.0]
  def change
    create_table :credits do |t|
      t.references :currency, null: false, foreign_key: true
      t.bigint :amount
      t.references :organization, null: false, foreign_key: true
      t.references :account, foreign_key: true

      t.timestamps
    end
  end
end

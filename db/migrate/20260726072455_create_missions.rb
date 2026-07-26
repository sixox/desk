class CreateMissions < ActiveRecord::Migration[7.0]
  def change
    create_table :missions do |t|
      t.references :user, null: false, foreign_key: true

      t.date :start_at
      t.date :end_at
      t.string :mission_type
      t.text :description
      t.boolean :confirmed, default: false, null: false
      t.date :confirmed_at
      t.string :where

      t.timestamps
    end

    add_index :missions, [:user_id, :confirmed]
  end
end
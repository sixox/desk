class CreateActions < ActiveRecord::Migration[7.0]
  def change
    create_table :actions do |t|
      t.references :meeting, null: false, foreign_key: true
      t.references :user
      t.text :description
      t.date :deadline

      t.timestamps
    end
  end
end

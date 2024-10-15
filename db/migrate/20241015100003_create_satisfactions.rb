class CreateSatisfactions < ActiveRecord::Migration[7.0]
  def change
    create_table :satisfactions do |t|
      t.string :category, null: false
      t.text :question, null: false

      t.timestamps
    end
  end
end

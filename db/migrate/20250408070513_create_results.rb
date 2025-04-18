class CreateResults < ActiveRecord::Migration[7.0]
  def change
    create_table :results do |t|
      t.references :target, null: false, foreign_key: true
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end

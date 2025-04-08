class CreateKpis < ActiveRecord::Migration[7.0]
  def change
    create_table :kpis do |t|
      t.references :result, null: false, foreign_key: true
      t.decimal :value, null: false, precision: 10, scale: 2
      t.string :unit
      t.text :comment

      t.timestamps
    end
  end
end

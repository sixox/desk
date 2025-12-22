class CreateDayOffs < ActiveRecord::Migration[7.0]
  def change
    create_table :day_offs do |t|
      t.references :shamsi_month, null: false, foreign_key: true
      t.date :day

      t.timestamps
    end
  end
end

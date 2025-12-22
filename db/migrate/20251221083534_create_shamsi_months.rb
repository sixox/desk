class CreateShamsiMonths < ActiveRecord::Migration[7.0]
  def change
    create_table :shamsi_months do |t|
      t.string :name
      t.datetime :start_at
      t.datetime :end_at
      t.integer :total_days
      t.integer :off_days

      t.timestamps
    end
  end
end

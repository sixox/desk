# db/migrate/XXXXXXXXXXXXXX_create_shamsi_month_remote_days.rb
class CreateShamsiMonthRemoteDays < ActiveRecord::Migration[7.0]
  def change
    create_table :shamsi_month_remote_days do |t|
      t.references :shamsi_month, null: false, foreign_key: true
      t.date :day, null: false
      t.timestamps
    end

    add_index :shamsi_month_remote_days, [:shamsi_month_id, :day], unique: true
  end
end

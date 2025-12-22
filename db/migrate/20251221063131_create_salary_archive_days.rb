class CreateSalaryArchiveDays < ActiveRecord::Migration[7.0]
  def change
    create_table :salary_archive_days do |t|
      t.references :salary_archive, null: false, foreign_key: true
      t.date :work_date
      t.datetime :first_in_at
      t.datetime :last_out_at
      t.integer :work_minutes
      t.integer :overtime_minutes
      t.integer :deficit_minutes
      t.integer :manual_adjust_minutes
      t.text :note

      t.timestamps
    end
  end
end

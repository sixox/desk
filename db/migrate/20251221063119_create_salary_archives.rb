class CreateSalaryArchives < ActiveRecord::Migration[7.0]
  def change
    create_table :salary_archives do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shamsi_month, null: false, foreign_key: true
      t.integer :status
      t.integer :total_work_minutes
      t.integer :overtime_minutes
      t.integer :deficit_minutes
      t.integer :manual_overtime_minutes
      t.integer :manual_deficit_minutes
      t.decimal :bonus
      t.decimal :penalty
      t.text :notes
      t.datetime :manager_confirmed_at
      t.references :manager_confirmed_by, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class CreatePayrollDays < ActiveRecord::Migration[7.0]
  def change
    create_table :payroll_days do |t|
      t.references :payroll_month, null: false, foreign_key: true
      t.date    :day_on, null: false
      t.boolean :holiday, default: false, null: false
      t.string  :note

      t.timestamps
    end

    add_index :payroll_days, [:payroll_month_id, :day_on], unique: true
  end
end

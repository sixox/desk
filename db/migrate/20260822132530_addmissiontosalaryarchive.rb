class Addmissiontosalaryarchive < ActiveRecord::Migration[7.0]
 def change
    add_column :salary_archives, :mission_working_minutes, :integer, null: false, default: 0
    add_column :salary_archives, :mission_non_working_minutes, :integer, null: false, default: 0
    add_column :salary_archives, :mission_holiday_working_minutes, :integer, null: false, default: 0

    add_column :salary_archives, :mission_working_pay, :decimal, precision: 15, scale: 2, null: false, default: 0
    add_column :salary_archives, :mission_non_working_pay, :decimal, precision: 15, scale: 2, null: false, default: 0
    add_column :salary_archives, :mission_holiday_working_pay, :decimal, precision: 15, scale: 2, null: false, default: 0
    add_column :salary_archives, :mission_total_pay, :decimal, precision: 15, scale: 2, null: false, default: 0
  end
end

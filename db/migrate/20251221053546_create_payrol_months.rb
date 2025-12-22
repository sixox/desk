class CreatePayrolMonths < ActiveRecord::Migration[7.0]
  def change
    create_table :payroll_months do |t|
      t.string  :title                      # مثلا "1404-10"
      t.date    :start_on, null: false
      t.date    :end_on,   null: false
      t.integer :days_count, null: false    # همونی که خودت وارد می‌کنی

      t.timestamps
    end
  end
end

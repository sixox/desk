class CreateSallaryProfile < ActiveRecord::Migration[7.0]
  def change
    create_table :salary_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :pay_type, null: false, default: 0 # enum

      # مزایا/ثوابت
      t.bigint :seniority_base, default: 0, null: false
      t.bigint :housing_allowance, default: 0, null: false
      t.bigint :food_allowance, default: 0, null: false
      t.bigint :marriage_allowance, default: 0, null: false
      t.bigint :child_allowance, default: 0, null: false
      t.bigint :total_salary, default: 0, null: false

      # برای حقوق ساعتی/انعطاف:
      t.decimal :hourly_rate, precision: 12, scale: 2 # اگر لازم شد
      t.integer :monthly_vacation_quota, default: 100, null: false # فعلاً 100

      t.timestamps
    end
  end
end

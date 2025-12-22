class AddFinancialFieldsToSalaryArchives < ActiveRecord::Migration[7.0]
  def change
    change_table :salary_archives, bulk: true do |t|
      t.bigint :seniority_base,     null: false, default: 0
      t.bigint :housing_allowance,  null: false, default: 0
      t.bigint :food_allowance,     null: false, default: 0
      t.bigint :marriage_allowance, null: false, default: 0
      t.bigint :child_allowance,    null: false, default: 0
      t.bigint :total_salary,       null: false, default: 0
      t.decimal :hourly_rate, precision: 12, scale: 2

      t.bigint :loan_installment,   null: false, default: 0
      t.bigint :fund_three_percent, null: false, default: 0
      t.bigint :fund_six_percent,   null: false, default: 0
    end
  end
end

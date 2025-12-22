class AddMonthlySeniorityAndInsuranceToSalaryArchives < ActiveRecord::Migration[7.0]
  def change
    change_table :salary_archives, bulk: true do |t|
      t.bigint :monthly_seniority_base, null: false, default: 0  # پایه سنوات ماهانه
      t.bigint :insurance,             null: false, default: 0  # 7% بیمه
    end
  end
end

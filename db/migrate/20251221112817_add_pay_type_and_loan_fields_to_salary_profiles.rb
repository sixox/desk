class AddPayTypeAndLoanFieldsToSalaryProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :salary_profiles, :loan_installment, :bigint, default: 0, null: false
    add_column :salary_profiles, :fund_three_percent, :bigint, default: 0, null: false
    add_column :salary_profiles, :fund_six_percent, :bigint, default: 0, null: false
  end
end

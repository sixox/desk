class AddMonthlySeniorityBaseToSalaryProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :salary_profiles, :monthly_seniority_base, :bigint, null: false, default: 0
  end
end

class AddRemainVacationsToSalaryProfile < ActiveRecord::Migration[7.0]
  def change
    add_column :salary_profiles, :remain_vacation, :integer
  end
end

class ChangeRemainVacationToDecimal < ActiveRecord::Migration[7.0]
  def change
    change_column :salary_profiles, :remain_vacation, :float
  end
end

class AddYearAndPeriodToSatisfactionForms < ActiveRecord::Migration[7.0]
  def change
    add_column :satisfaction_forms, :year, :integer
    add_column :satisfaction_forms, :period, :integer
  end
end

class AddYearAndPeriodToAssessmentForms < ActiveRecord::Migration[7.0]
  def change
    add_column :assessment_forms, :year, :integer
    add_column :assessment_forms, :period, :integer
  end
end

class CreateStakeholderSurveyForms < ActiveRecord::Migration[7.0]
  def change
    create_table :stakeholder_survey_forms do |t|
      t.references :user, null: false, foreign_key: true
      t.references :stakeholder_survey, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :period, null: false
      t.integer :answer
      t.text :feedback

      t.timestamps
    end
  end
end

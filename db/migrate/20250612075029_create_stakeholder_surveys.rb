class CreateStakeholderSurveys < ActiveRecord::Migration[7.0]
  def change
    create_table :stakeholder_surveys do |t|
      t.text :question_text, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end

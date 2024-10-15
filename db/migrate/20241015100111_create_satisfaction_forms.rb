class CreateSatisfactionForms < ActiveRecord::Migration[7.0]
  def change
    create_table :satisfaction_forms do |t|
      t.references :user, null: false, foreign_key: true
      t.references :satisfaction, null: false, foreign_key: true
      t.integer :answer, limit: 1 # Storing answer as an integer, with a limit between 1 and 6.

      t.timestamps
    end
  end
end

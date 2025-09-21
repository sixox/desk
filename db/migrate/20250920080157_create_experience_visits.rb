class CreateExperienceVisits < ActiveRecord::Migration[7.0]
  def change
    create_table :experience_visits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :experience, null: false, foreign_key: true

      t.timestamps
    end
  end
end

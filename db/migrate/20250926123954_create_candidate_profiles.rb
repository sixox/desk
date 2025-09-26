class CreateCandidateProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :candidate_profiles do |t|
      t.references :candidate, null: false, foreign_key: true
      t.json :data

      t.timestamps
    end
  end
end

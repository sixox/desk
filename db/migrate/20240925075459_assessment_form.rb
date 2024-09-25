class AssessmentForm < ActiveRecord::Migration[7.0]
  def change
    create_table :assessment_forms do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :filler, null: false, foreign_key: { to_table: :users }
      t.integer :score
      t.integer :weight
      t.integer :total_score

      t.timestamps
    end
  end
end

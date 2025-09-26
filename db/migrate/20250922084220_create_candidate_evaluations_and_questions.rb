# db/migrate/20250922_create_candidate_evaluations_and_questions.rb
class CreateCandidateEvaluationsAndQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :candidate_evaluations do |t|
      t.references :candidate, null: false, foreign_key: true
      t.references :user,      null: false, foreign_key: true  # evaluator
      t.string :department,    null: false                     # "HR", "CEO", "Accounting", "Other"
      t.text   :comment
      t.string :overall_grade  # "A+", "A", "B", "C", "D"
      t.timestamps
    end

    add_index :candidate_evaluations, [:candidate_id, :department], unique: true

    create_table :candidate_evaluation_questions do |t|
      t.references :candidate_evaluation, null: false, foreign_key: true
      t.integer :position, null: false, default: 1
      t.string  :text,     null: false        # question label
      t.integer :weight,   null: false, default: 2  # 1..3
      t.integer :score                       # 1..5 (can be nil before answer)
      t.boolean :fixed, default: false       # true for department’s fixed questions
      t.timestamps
    end

    add_index :candidate_evaluation_questions, [:candidate_evaluation_id, :position], unique: true, name: "idx_eval_questions_on_eval_and_position"
  end
end

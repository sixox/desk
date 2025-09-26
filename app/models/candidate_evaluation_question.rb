# app/models/candidate_evaluation_question.rb
class CandidateEvaluationQuestion < ApplicationRecord
  belongs_to :candidate_evaluation

  validates :position, presence: true
  validates :text, presence: true, if: :fixed?
  validates :weight, inclusion: { in: 1..3 }, allow_nil: true
  validates :score,  inclusion: { in: 1..5 }, allow_nil: true
end

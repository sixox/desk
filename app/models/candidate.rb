# app/models/candidate.rb
class Candidate < ApplicationRecord
  has_secure_password

  has_many :candidate_evaluations, dependent: :destroy

  has_one  :candidate_evaluation_hr,         -> { where(department: "HR") },        class_name: "CandidateEvaluation", dependent: :destroy
  has_one  :candidate_evaluation_ceo,        -> { where(department: "CEO") },       class_name: "CandidateEvaluation", dependent: :destroy
  has_one  :candidate_evaluation_accounting, -> { where(department: "Accounting") },class_name: "CandidateEvaluation", dependent: :destroy
  has_one  :candidate_evaluation_other,      -> { where(department: "Other") },     class_name: "CandidateEvaluation", dependent: :destroy
  has_one :candidate_profile, dependent: :destroy  # <-- ADD THIS


  validates :name, :phone, :role, :password, presence: true
  validates :phone, uniqueness: true
end

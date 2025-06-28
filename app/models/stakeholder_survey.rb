class StakeholderSurvey < ApplicationRecord
  has_many :stakeholder_survey_forms, dependent: :destroy

  validates :question_text, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
end

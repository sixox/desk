class QuarterlyEvaluation < ApplicationRecord
  belongs_to :user
  belongs_to :kpi_list

  has_many :done_actions, dependent: :destroy
  has_many :undone_actions, dependent: :destroy

  accepts_nested_attributes_for :done_actions, allow_destroy: true
  accepts_nested_attributes_for :undone_actions, allow_destroy: true

  validates :year, presence: true
  validates :period, presence: true, inclusion: { in: 1..4 }

  has_many_attached :files
end

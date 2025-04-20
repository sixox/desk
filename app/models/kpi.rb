class Kpi < ApplicationRecord
  belongs_to :result
  validates :comment, presence: true


  # validates :value, presence: true, numericality: true
end

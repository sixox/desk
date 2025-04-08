class Kpi < ApplicationRecord
  belongs_to :result

  # validates :value, presence: true, numericality: true
end

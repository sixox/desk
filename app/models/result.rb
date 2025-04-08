class Result < ApplicationRecord
  belongs_to :target
  has_one :kpi, dependent: :destroy

  validates :description, presence: true
end

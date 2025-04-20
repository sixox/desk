class Result < ApplicationRecord
  belongs_to :target
  has_one :kpi, dependent: :destroy
  accepts_nested_attributes_for :kpi


  validates :description, presence: true
end

class Result < ApplicationRecord
  belongs_to :target
  has_one :kpi, dependent: :destroy
  accepts_nested_attributes_for :kpi

  has_many :done_actions
  has_many :undone_actions


  validates :description, presence: true
end

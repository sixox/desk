class KpiList < ApplicationRecord
  belongs_to :user
  has_many :targets, dependent: :destroy
  accepts_nested_attributes_for :targets, allow_destroy: true


  validates :year, :period, presence: true
  validates :period, inclusion: { in: 0..4 } # 0 = whole year, 1-4 = quarters
  validates :year, numericality: { greater_than_or_equal_to: 1400 }
end

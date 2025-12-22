class DayOff < ApplicationRecord
  belongs_to :shamsi_month
  validates :day, presence: true
end

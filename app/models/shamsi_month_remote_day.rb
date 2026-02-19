# app/models/shamsi_month_remote_day.rb
class ShamsiMonthRemoteDay < ApplicationRecord
  belongs_to :shamsi_month

  validates :day, presence: true
  validates :day, uniqueness: { scope: :shamsi_month_id }
end

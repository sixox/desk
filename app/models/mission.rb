class Mission < ApplicationRecord
  belongs_to :user

  has_many_attached :documents

  TYPES = [
    "Business Trip",
    "Training",
    "Meeting",
    "Conference"
  ].freeze



  validates :start_at, :end_at, :mission_type, :description, presence: true
  validates :mission_type, inclusion: { in: TYPES }

  validate :end_at_after_start_at

def hours_for_date(date)
  return {
    working_hours: 0.0,
    non_working_hours: 0.0
  } if start_at.blank? || end_at.blank?

  date = date.to_date

  day_start = date.beginning_of_day
  day_end   = (date + 1.day).beginning_of_day

  interval_start = [start_at, day_start].max
  interval_end   = [end_at, day_end].min

  return {
    working_hours: 0.0,
    non_working_hours: 0.0
  } if interval_end <= interval_start

  work_start = date.in_time_zone.change(hour: 8, min: 30)

  work_end =
    if date.thursday?
      date.in_time_zone.change(hour: 12, min: 30)
    else
      date.in_time_zone.change(hour: 16, min: 30)
    end

  total_seconds = interval_end - interval_start

  working_start = [interval_start, work_start].max
  working_end   = [interval_end, work_end].min

  working_seconds =
    if working_end > working_start
      working_end - working_start
    else
      0
    end

  non_working_seconds = [total_seconds - working_seconds, 0].max

  {
    working_hours: (working_seconds / 1.hour).round(2),
    non_working_hours: (non_working_seconds / 1.hour).round(2)
  }
end

def daily_hours
  result = {}

  return result if start_at.blank? || end_at.blank? || end_at <= start_at

  current_day = start_at.to_date

  while current_day <= end_at.to_date
    result[current_day] = hours_for_date(current_day)
    current_day += 1.day
  end

  result
end


def self.for_date(user, date)
  where(user: user)
    .where("DATE(start_at) <= ? AND DATE(end_at) >= ?", date, date)
end

  private

  def end_at_after_start_at
    return if start_at.blank? || end_at.blank?

    if end_at < start_at
      errors.add(:end_at, "must be on or after the start date")
    end
  end

end

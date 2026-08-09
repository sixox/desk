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

  def daily_hours
    result = {}

    return result if start_at.blank? || end_at.blank? || end_at <= start_at

    current_day = start_at.to_date

    while current_day <= end_at.to_date
      day_start = current_day.beginning_of_day
      day_end   = (current_day + 1.day).beginning_of_day

      interval_start = [start_at, day_start].max
      interval_end   = [end_at, day_end].min

      total_seconds = [interval_end - interval_start, 0].max

      if current_day.thursday?
        work_end = current_day.in_time_zone.change(hour: 12, min: 30)
      else
        work_end = current_day.in_time_zone.change(hour: 16, min: 30)
      end

      work_start = current_day.in_time_zone.change(hour: 8, min: 30)

      overlap_start = [interval_start, work_start].max
      overlap_end   = [interval_end, work_end].min

      working_seconds =
      if overlap_end > overlap_start
        overlap_end - overlap_start
      else
        0
      end

      result[current_day] = {
        working_hours: (working_seconds / 1.hour).round(2),
        non_working_hours: ((total_seconds - working_seconds) / 1.hour).round(2)
      }

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

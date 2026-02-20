# app/models/salary_archive_day.rb
class SalaryArchiveDay < ApplicationRecord
  belongs_to :salary_archive

  TIME_RE = /\A([01]?\d|2[0-3]):([0-5]?\d)\z/

  # legacy compatibility
  def work_minutes_final
    work_minutes.to_i + manual_adjust_minutes.to_i
  end

  def computed_work_minutes
    minutes_from_times = minutes_from_entry_exit
    return minutes_from_times unless minutes_from_times.nil?
    work_minutes.to_i
  end

  def computed_work_minutes_final
    computed_work_minutes.to_i + manual_adjust_minutes.to_i
  end

  before_save :sync_work_minutes_from_times

  private

  def minutes_from_entry_exit
    in_min  = parse_hhmm_to_minutes(first_in_at)
    out_min = parse_hhmm_to_minutes(last_out_at)
    return nil unless in_min && out_min

    out_min += 24 * 60 if out_min < in_min # crosses midnight
    diff = out_min - in_min
    diff.negative? ? 0 : diff
  end

  def parse_hhmm_to_minutes(value)
    s = value.to_s.strip
    return nil if s.blank?
    m = TIME_RE.match(s)
    return nil unless m
    hh = m[1].to_i
    mm = m[2].to_i
    (hh * 60) + mm
  end

  def sync_work_minutes_from_times
    mins = minutes_from_entry_exit
    return if mins.nil?
    self.work_minutes = mins
  end
end
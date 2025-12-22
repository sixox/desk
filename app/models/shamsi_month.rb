# app/models/shamsi_month.rb
class ShamsiMonth < ApplicationRecord
  has_many :day_offs, dependent: :destroy
  has_many :salary_archives, dependent: :destroy

  after_create :schedule_archive_build

  validates :name, :start_at, :end_at, :total_days, presence: true

  # Returns list of off dates (Fridays + custom day_offs)
  def off_dates
    all_dates = (start_at.to_date..end_at.to_date).to_a
    fridays = all_dates.select(&:friday?)
    custom = day_offs.map(&:day)
    (fridays + custom).uniq
  end

  private

  def schedule_archive_build
    return if end_at.blank?

    run_at = end_at.to_date.next_day.beginning_of_day + 5.minutes
    GenerateArchivesJob.set(wait_until: run_at).perform_later(id)
  end
end

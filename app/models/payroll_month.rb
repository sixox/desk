class PayrollMonth < ApplicationRecord
  has_many :payroll_days, dependent: :destroy
  accepts_nested_attributes_for :payroll_days

  validates :start_on, :end_on, :days_count, presence: true

  validate :range_matches_days_count

  after_create :generate_days!

  private

  def range_matches_days_count
    return if start_on.blank? || end_on.blank? || days_count.blank?

    actual = (end_on - start_on).to_i + 1
    if actual != days_count
      errors.add(:days_count, "does not match the range (range has #{actual} days)")
    end
  end

  def generate_days!
    # برای هر روز، رکورد بساز و جمعه‌ها رو تعطیل کن
    (start_on..end_on).each do |d|
      payroll_days.create!(
        day_on: d,
        holiday: d.friday? # ✅ همه جمعه‌ها اتومات تعطیل
      )
    end
  end
end

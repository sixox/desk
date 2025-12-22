# app/models/manual_entry.rb
class ManualEntry < ApplicationRecord
  belongs_to :user

  validates :occurred_at, presence: true
  validates :is_entry, inclusion: { in: [true, false] }
  validates :description, presence: true

  validate :unique_type_per_day

  scope :on_date, ->(date) { where(occurred_at: date.beginning_of_day..date.end_of_day) }

  private

  def unique_type_per_day
    return if occurred_at.blank?

    d = occurred_at.to_date
    exists = ManualEntry
      .where(user_id: user_id, is_entry: is_entry)
      .where(occurred_at: d.beginning_of_day..d.end_of_day)

    exists = exists.where.not(id: id) if persisted?

    if exists.exists?
      errors.add(:base, "برای این روز یک مورد #{is_entry ? 'ورود' : 'خروج'} دستی قبلاً ثبت شده")
    end
  end
end

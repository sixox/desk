# app/models/overtime_entry.rb
class OvertimeEntry < ApplicationRecord
  belongs_to :user

  validates :date, presence: true
  validates :hours, presence: true, numericality: { greater_than: 0 }
  validates :reason, presence: true
  validates :confirmed, inclusion: { in: [true, false] }
  validates :outside_system, inclusion: { in: [true, false] }

  validates :date, uniqueness: { scope: :user_id, message: "برای این تاریخ قبلاً اضافه‌کاری ثبت شده" }

  attribute :confirmed, :boolean, default: true
  attribute :outside_system, :boolean, default: false
end

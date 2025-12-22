class SalaryArchive < ApplicationRecord
  belongs_to :user
  belongs_to :shamsi_month

  belongs_to :manager_confirmed_by, class_name: "User", optional: true

  has_many :days, class_name: "SalaryArchiveDay", dependent: :destroy

  enum status: { draft: 0, manager_confirmed: 1 }

  validates :user_id, uniqueness: { scope: :shamsi_month_id }

  def total_overtime_minutes_final
    (overtime_minutes.to_i + manual_overtime_minutes.to_i)
  end

  def total_deficit_minutes_final
    (deficit_minutes.to_i + manual_deficit_minutes.to_i)
  end

  def confirmed?
    manager_confirmed_at.present?
  end

  def recalculate_totals!
    self.total_work_minutes = days.sum(:work_minutes)
    self.overtime_minutes   = days.sum(:overtime_minutes)
    self.deficit_minutes    = days.sum(:deficit_minutes)
    save!
  end
end

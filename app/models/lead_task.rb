# app/models/lead_task.rb
class LeadTask < ApplicationRecord
  belongs_to :lead
  belongs_to :assigned_to, class_name: "User", optional: true

  enum status: { open: 0, done: 1 }

  validates :title, presence: true

  scope :overdue, -> { open.where("due_on < ?", Date.current) }
  scope :due_today, -> { open.where(due_on: Date.current) }
  scope :due_upcoming, -> { open.where(due_on: Date.current..(Date.current + 7.days)) }

  before_save :stamp_completed_at, if: :will_save_change_to_status?

  def stamp_completed_at
    self.completed_at = (done? ? Time.current : nil)
  end

  def due_badge_class
    return "bg-secondary" if due_on.blank?
    return "bg-danger"    if due_on < Date.current
    return "bg-warning text-dark" if due_on == Date.current
    "bg-info text-dark"
  end
end

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

  private

  def end_at_after_start_at
    return if start_at.blank? || end_at.blank?

    if end_at < start_at
      errors.add(:end_at, "must be on or after the start date")
    end
  end

end

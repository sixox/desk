class Vacation < ApplicationRecord
  belongs_to :user

  enum vacation_type: {
    estehghaghi: 'estehghaghi',
    estelaji: 'estelaji'
  }

  validates :start_at, :end_at, :vacation_type, :details, presence: true
  validate :hourly_or_daily

  def hourly_or_daily
    if start_at.present? && end_at.present?
      if start_at >= end_at
        errors.add(:end_at, "must be greater than start date")
      elsif start_at.to_date != end_at.to_date && hourly
        errors.add(:hourly, 'cannot be Hourly when you choose more than a working day')
        
      end
    end
  end
end

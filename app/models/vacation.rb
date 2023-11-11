class Vacation < ApplicationRecord
  belongs_to :user



  VACATION_TYPE = ['Paid', 'Unpaid', 'Medical']

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

  def days
    if hourly
      "#{(end_at.to_date - start_at.to_date).to_i}"
    else
      "#{(end_at.to_date - start_at.to_date + 1).to_i}"
    end
  end


  
end




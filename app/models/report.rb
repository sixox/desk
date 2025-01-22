class Report < ApplicationRecord
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy

  has_many_attached :documents

  scope :by_user_role, ->(roles) { 
    joins(:user).where(users: { role: Array(roles) }) 
  }

  def created_within_24_hours?
    created_at >= 24.hours.ago
  end



end

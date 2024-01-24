class Report < ApplicationRecord
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy

  has_many_attached :documents

  scope :by_user_role, -> (role) { joins(:user).where(users: { role: role }) }



end

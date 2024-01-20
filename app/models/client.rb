class Client < ApplicationRecord
  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy

  STATUSES = ['New', 'Following', 'Wait for offer', 'Wait for LOI', 'Wait for feedback', 'Rejected']

end

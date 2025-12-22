class UserManagerMapping < ApplicationRecord
  belongs_to :user
  belongs_to :manager, class_name: "User"

  validates :user_id, presence: true, uniqueness: true
  validates :manager_id, presence: true
end

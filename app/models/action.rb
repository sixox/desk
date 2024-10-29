class Action < ApplicationRecord
  belongs_to :meeting
  belongs_to :user

  validates :description, :deadline, presence: true
end

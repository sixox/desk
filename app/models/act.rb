class Act < ApplicationRecord
  belongs_to :message
  belongs_to :user


  ACTION_TYPES = {
    "happy" => "Happy",
    "sad" => "Sad",
    "agree" => "Agree",
    "disagree" => "Disagree",
    "like" => "Like"
  }.freeze
  validates :action_type, inclusion: { in: ACTION_TYPES, message: "%{value} is not a valid action type" }
end

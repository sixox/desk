class MessageTag < ApplicationRecord
  belongs_to :message
  belongs_to :user

  validates :tag, presence: true
  validates :tag, uniqueness: { scope: [:message_id, :user_id], message: "Tag already added by this user" }
end

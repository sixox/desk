class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  has_many :message_observers, dependent: :destroy
  has_many :observers, through: :message_observers, source: :observer
  has_one :message_status, dependent: :destroy # Change from has_many to has_one
  has_many :acts, dependent: :destroy

  has_many_attached :files
  has_many :comments, as: :commentable, dependent: :destroy


  after_create :create_receiver_status

  validates :sender_id, presence: true, exclusion: { in: ->(msg) { [msg.receiver_id] }, message: "cannot be the same as receiver" }
  validates :receiver_id, :subject, :body, presence: true


  private

  def create_receiver_status
    create_message_status(user: receiver, status: 'unread') # Use singular `create_message_status`
  end
end

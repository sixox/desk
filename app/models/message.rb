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
  before_save :sanitize_body


  validates :sender_id, presence: true, exclusion: { in: ->(msg) { [msg.receiver_id] }, message: "cannot be the same as receiver" }
  validates :receiver_id, :subject, :body, presence: true
  def read_by?(user)
    return true if sender == user # Sender always considers it read

    if receiver == user
      # Check message status for receiver
      message_status && message_status.status != 'unread'
    elsif observers.exists?(id: user.id)
      # Check message_observers for this user
      message_observers.where(observer_id: user.id, read: true).exists?
    else
      false
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ['id', 'subject'] # Add any other attributes of the Message model you want to search on
  end

  def self.ransackable_associations(auth_object = nil)
    ['sender', 'receiver'] # Allow search on these associations
  end

  private

  def sanitize_body
    # Strip unnecessary spaces while preserving line breaks
    self.body = body.to_s.strip if body.present?
  end

  def create_receiver_status
    create_message_status(user: receiver, status: 'unread') # Use singular `create_message_status`
  end
end

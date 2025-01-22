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

  def star_message!(current_user)
    ActiveRecord::Base.transaction do
      # Update the message's star column if the current user is not the sender
      update!(star: true) unless sender_id == current_user.id

      # Update the star status in message_status if the current user is not the receiver
      message_status&.update!(star: true) unless receiver_id == current_user.id

      # Update the star status for all observers except the current user
      message_observers.where.not(observer_id: current_user.id).update_all(star: true)
    end
  rescue => e
    Rails.logger.error("Failed to star message: #{e.message}")
    false
  end


  def star_for_user(user)
    if sender_id == user.id
      star # Sender's star value is from the message itself
    elsif receiver_id == user.id
      message_status&.star # Receiver's star value is from message_status
    else
      observer = message_observers.find_by(observer_id: user.id)
      observer&.star # Observer's star value is from message_observers
    end
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

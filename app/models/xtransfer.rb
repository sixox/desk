class Xtransfer < ApplicationRecord
  # ==================================================
  # MOVEMENTS
  # ==================================================

  has_many :money_movements,
           as: :movable,
           dependent: :destroy

  has_many :sends,
           -> { where(direction: "send") },
           as: :movable,
           class_name: "MoneyMovement"

  has_many :receives,
           -> { where(direction: "receive") },
           as: :movable,
           class_name: "MoneyMovement"

  accepts_nested_attributes_for :money_movements,
                                allow_destroy: true,
                                reject_if: :all_blank


  # ==================================================
  # EXCHANGES
  # ==================================================

  has_many :exchange_transfers,
           dependent: :destroy

  has_many :exchanges,
           through: :exchange_transfers

  accepts_nested_attributes_for :exchange_transfers,
                              allow_destroy: true,
                              reject_if: proc { |attributes|
                                attributes["exchange_id"].blank?
                              }


  # ==================================================
  # TRANSACTIONS
  # ==================================================

  has_many :xtransactions,
           -> { order(id: :desc) },
           as: :transactionable,
           dependent: :restrict_with_error


  # ==================================================
  # ATTACHMENTS
  # ==================================================

  has_many_attached :documents


  # ==================================================
  # COMMENTS
  # ==================================================

  has_many :comments,
           as: :commentable,
           dependent: :destroy


  # ==================================================
  # VALIDATIONS
  # ==================================================

  validates :status,
            presence: true



  # ==================================================
  # SCOPES
  # ==================================================

  scope :pending, -> {
    where(pending: true)
  }


  # ==================================================
  # ACCOUNTING
  # ==================================================

  # Xtransfer accounting is entirely defined by its
  # MoneyMovement records.
  #
  # Every SEND:
  #
  #   debit
  #
  # Every RECEIVE:
  #
  #   credit
  #


  # ==================================================
  # MOVEMENT HELPERS
  # ==================================================

  def sends
    active_money_movements.select(&:send?)
  end


  def receives
    active_money_movements.select(&:receive?)
  end


  def total_sent
    sends.sum do |movement|
      movement.total.to_i
    end
  end


  def total_received
    receives.sum do |movement|
      movement.total.to_i
    end
  end


  # ==================================================
  # PENDING
  # ==================================================

  def set_pending!
    update!(
      pending: true,
      pending_set_time: Time.current
    )
  end


  def unset_pending!
    update!(
      pending: false,
      pending_set_time: nil
    )
  end


  # ==================================================
  # DISPLAY HELPERS
  # ==================================================

  def send_count
    sends.size
  end


  def receive_count
    receives.size
  end


  private


  # ==================================================
  # ACTIVE MOVEMENTS
  # ==================================================

  def active_money_movements
    money_movements.reject(&:marked_for_destruction?)
  end


  # ==================================================
  # REQUIRE SEND
  # ==================================================

 
end
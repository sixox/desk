class Remittance < ApplicationRecord
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
  # VALIDATIONS
  # ==================================================

  validate :must_have_send_movement
  validate :must_have_receive_movement


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

  def must_have_send_movement
    return if sends.any?

    errors.add(
      :money_movements,
      "must contain at least one send"
    )
  end


  # ==================================================
  # REQUIRE RECEIVE
  # ==================================================

  def must_have_receive_movement
    return if receives.any?

    errors.add(
      :money_movements,
      "must contain at least one receive"
    )
  end
end
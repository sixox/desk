class Exchange < ApplicationRecord
  # ==================================================
  # MOVEMENTS
  # ==================================================

  has_many :exchange_movements,
           dependent: :destroy

  has_many :sells,
           -> { where(direction: "sell") },
           class_name: "ExchangeMovement",
           inverse_of: :exchange

  has_many :buys,
           -> { where(direction: "buy") },
           class_name: "ExchangeMovement",
           inverse_of: :exchange

  accepts_nested_attributes_for :exchange_movements,
                                allow_destroy: true,
                                reject_if: :all_blank


  # ==================================================
  # RELATED TRANSFERS
  # ==================================================

  has_many :exchange_transfers,
           dependent: :destroy

  has_many :xtransfers,
           through: :exchange_transfers


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
  # KIND
  # ==================================================

  enum kind: {
    cross_currency: 0,
    same_currency: 1,
    currency_exchange: 2
  }


  # ==================================================
  # VALIDATIONS
  # ==================================================

  validates :kind,
            presence: true

  validate :must_have_sell_movement
  validate :must_have_buy_movement


  # ==================================================
  # MOVEMENT HELPERS
  # ==================================================

  def sells
    active_exchange_movements.select(&:sell?)
  end


  def buys
    active_exchange_movements.select(&:buy?)
  end


  def total_sold
    sells.sum do |movement|
      movement.total.to_i
    end
  end


  def total_bought
    buys.sum do |movement|
      movement.total.to_i
    end
  end


  def sell_count
    sells.size
  end


  def buy_count
    buys.size
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


  private


  # ==================================================
  # ACTIVE MOVEMENTS
  # ==================================================

  def active_exchange_movements
    exchange_movements.reject(&:marked_for_destruction?)
  end


  # ==================================================
  # REQUIRE SELL
  # ==================================================

  def must_have_sell_movement
    return if sells.any?

    errors.add(
      :exchange_movements,
      "must contain at least one sell"
    )
  end


  # ==================================================
  # REQUIRE BUY
  # ==================================================

  def must_have_buy_movement
    return if buys.any?

    errors.add(
      :exchange_movements,
      "must contain at least one buy"
    )
  end
end
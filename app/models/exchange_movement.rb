class ExchangeMovement < ApplicationRecord
  # ==================================================
  # CONSTANTS
  # ==================================================

  DIRECTIONS = %w[
    sell
    buy
  ].freeze

  ACCOUNTING_SIDES = {
    "sell" => "debit",
    "buy" => "credit"
  }.freeze


  # ==================================================
  # ASSOCIATIONS
  # ==================================================

  belongs_to :exchange

  belongs_to :xaccount

  belongs_to :currency

  belongs_to :to_currency,
             class_name: "Currency",
             optional: true

  has_many :xtransactions,
           -> { order(id: :asc) },
           as: :transactionable,
           dependent: :restrict_with_error


  # ==================================================
  # VALIDATIONS
  # ==================================================

  validates :direction,
            presence: true,
            inclusion: {
              in: DIRECTIONS
            }

  validates :exchange,
            presence: true

  validates :xaccount,
            presence: true

  validates :currency,
            presence: true

  validates :amount,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true
            }

  validates :charge,
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true
            }

  validates :total,
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true
            }

  validates :exchange_rate,
            numericality: {
              greater_than: 0
            },
            allow_blank: true

  validates :amount_to,
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true
            },
            allow_nil: true

  validate :currency_matches_account
  validate :exchange_rate_requires_to_currency
  validate :to_currency_requires_exchange_rate


  # ==================================================
  # CALLBACKS
  # ==================================================

  before_validation :calculate_amounts


  # ==================================================
  # SCOPES
  # ==================================================

  scope :sells,
        -> { where(direction: "sell") }

  scope :buys,
        -> { where(direction: "buy") }


  # ==================================================
  # DIRECTION
  # ==================================================

  def sell?
    direction == "sell"
  end


  def buy?
    direction == "buy"
  end


  # ==================================================
  # ACCOUNTING SIDE
  #
  # Change this one mapping later if necessary.
  # ==================================================

  def accounting_side
    ACCOUNTING_SIDES.fetch(direction)
  end


  def debit?
    accounting_side == "debit"
  end


  def credit?
    accounting_side == "credit"
  end


  # ==================================================
  # ACCOUNTING AMOUNTS
  # ==================================================

  def debit_amount
    debit? ? total.to_i : 0
  end


  def credit_amount
    credit? ? total.to_i : 0
  end


  # ==================================================
  # XTRANSACTION
  # ==================================================

  def accounting_entry
    {
      xaccount_id: xaccount_id,
      currency_id: xaccount.currency_id,
      debit_amount: debit_amount,
      credit_amount: credit_amount
    }
  end


  def create_xtransaction!(user: nil, note: nil)
    Xtransaction.create_for_movement!(
      movement: self,
      user: user,
      note: note
    )
  end


  # ==================================================
  # CALCULATIONS
  # ==================================================

  def converted_amount
    amount_to.to_i
  end


  def calculated_total
    converted_amount + charge.to_i
  end


  # ==================================================
  # DISPLAY
  # ==================================================

  def direction_name
    direction.humanize
  end


  private


  # ==================================================
  # CALCULATE AMOUNTS
  # ==================================================

  def calculate_amounts
    self.amount =
      amount.to_i

    self.charge =
      charge.to_i

    self.amount_to =
      if exchange_rate.present? &&
         exchange_rate.to_f.positive?

        (
          amount.to_f *
          exchange_rate.to_f
        ).round

      else

        amount

      end

    self.total =
      amount_to.to_i +
      charge
  end


  # ==================================================
  # CURRENCY / ACCOUNT
  # ==================================================

  def currency_matches_account
    return if xaccount.blank?
    return if currency.blank?

    return if xaccount.currency_id == currency_id

    errors.add(
      :currency,
      "must match the Xaccount currency (#{xaccount.currency.name})"
    )
  end


  # ==================================================
  # EXCHANGE RATE
  # ==================================================

  def exchange_rate_requires_to_currency
    return if exchange_rate.blank?
    return if to_currency_id.present?

    errors.add(
      :to_currency,
      "must be selected when exchange rate is provided"
    )
  end


  def to_currency_requires_exchange_rate
    return if to_currency_id.blank?
    return if exchange_rate.present?

    errors.add(
      :exchange_rate,
      "must be provided when To Currency is selected"
    )
  end
end
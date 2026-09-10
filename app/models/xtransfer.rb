class Xtransfer < ApplicationRecord
  # ==================================================
  # ACCOUNTS
  # ==================================================

  belongs_to :sender_account,
             class_name: "Xaccount"

  belongs_to :receiver_account,
             class_name: "Xaccount"


  # ==================================================
  # CURRENCIES
  # ==================================================

  belongs_to :sender_currency,
             class_name: "Currency",
             optional: true

  belongs_to :sender_to_currency,
             class_name: "Currency",
             optional: true

  belongs_to :receiver_currency,
             class_name: "Currency",
             optional: true

  belongs_to :receiver_to_currency,
             class_name: "Currency",
             optional: true


  # ==================================================
  # EXCHANGES
  # ==================================================

  has_many :exchange_transfers,
           dependent: :destroy

  has_many :exchanges,
           through: :exchange_transfers


  # ==================================================
  # TRANSACTIONS
  # ==================================================

  has_many :xtransactions,
           as: :transactionable,
           dependent: :restrict_with_error


  # ==================================================
  # ATTACHMENTS
  # ==================================================

  has_many_attached :documents

  has_many :comments, as: :commentable, dependent: :destroy



  # ==================================================
  # VALIDATIONS
  # ==================================================

  # --------------------------------------------------
  # ACCOUNTS
  # --------------------------------------------------

  validates :sender_account_id,
            presence: true

  validates :receiver_account_id,
            presence: true

  validate :sender_account_belongs_to_organization
  validate :receiver_account_belongs_to_organization


  # --------------------------------------------------
  # AMOUNTS
  # --------------------------------------------------

  validates :sender_amount,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true
            }

  validates :receiver_amount,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true
            }


  # --------------------------------------------------
  # CURRENCIES
  # --------------------------------------------------

  validates :sender_currency,
            presence: true

  validates :receiver_currency,
            presence: true

  validate :sender_currency_matches_account
  validate :receiver_currency_matches_account


  # --------------------------------------------------
  # CHARGES
  # --------------------------------------------------

  validates :sender_charge,
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true
            }

  validates :receiver_charge,
            numericality: {
              greater_than_or_equal_to: 0,
              only_integer: true
            }


  # --------------------------------------------------
  # EXCHANGE RATES
  #
  # Rate is optional.
  #
  # If supplied, it must be greater than zero.
  # --------------------------------------------------

  validates :sender_exchange_rate,
            numericality: {
              greater_than: 0
            },
            allow_blank: true

  validates :receiver_exchange_rate,
            numericality: {
              greater_than: 0
            },
            allow_blank: true


  # --------------------------------------------------
  # EXCHANGE RATE / TO CURRENCY RELATION
  # --------------------------------------------------

  validate :sender_rate_requires_to_currency
  validate :receiver_rate_requires_to_currency


  # --------------------------------------------------
  # RECEIVER CURRENCY RELATION
  # --------------------------------------------------

  validate :receiver_currency_matches_sender_conversion


  # ==================================================
  # SCOPES
  # ==================================================

  scope :pending, -> {
    where(pending: true)
  }


  # ==================================================
  # CALCULATIONS
  # ==================================================

  before_validation :calculate_conversion_amounts


  def calculate_conversion_amounts

    # --------------------------------------------------
    # SENDER
    #
    # If sender exchange rate exists:
    #
    #   amount × rate
    #
    # Otherwise:
    #
    #   amount
    # --------------------------------------------------

    if sender_amount.present?

      if sender_exchange_rate.present? &&
         sender_exchange_rate.to_f > 0

        self.sender_amount_to =
          (
            sender_amount.to_f *
            sender_exchange_rate.to_f
          ).round

      else

        self.sender_amount_to =
          sender_amount.to_i

      end
    end


    # --------------------------------------------------
    # RECEIVER
    #
    # If receiver exchange rate exists:
    #
    #   amount ÷ rate
    #
    # Otherwise:
    #
    #   amount
    # --------------------------------------------------

    if receiver_amount.present?

      if receiver_exchange_rate.present? &&
         receiver_exchange_rate.to_f > 0

        self.receiver_amount_to =
          (
            receiver_amount.to_f /
            receiver_exchange_rate.to_f
          ).round

      else

        self.receiver_amount_to =
          receiver_amount.to_i

      end
    end


    # --------------------------------------------------
    # SENDER TOTAL
    # --------------------------------------------------

    if sender_amount.present?

      self.sender_total =
        sender_amount_to.to_i +
        sender_charge.to_i
    end


    # --------------------------------------------------
    # RECEIVER TOTAL
    # --------------------------------------------------

    if receiver_amount.present?

      self.receiver_total =
        receiver_amount_to.to_i +
        receiver_charge.to_i
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


  private


  # ==================================================
  # ACCOUNT VALIDATIONS
  # ==================================================

  def sender_account_belongs_to_organization
    return if sender_account.blank?

    unless sender_account.organization_id.present?
      errors.add(
        :sender_account_id,
        "must belong to an organization"
      )
    end
  end


  def receiver_account_belongs_to_organization
    return if receiver_account.blank?

    unless receiver_account.organization_id.present?
      errors.add(
        :receiver_account_id,
        "must belong to an organization"
      )
    end
  end


  # ==================================================
  # CURRENCY / ACCOUNT VALIDATIONS
  # ==================================================

  def sender_currency_matches_account
    return if sender_account.blank?
    return if sender_currency.blank?

    unless sender_currency_id == sender_account.currency_id
      errors.add(
        :sender_currency_id,
        "must match the sender account currency"
      )
    end
  end


  def receiver_currency_matches_account
    return if receiver_account.blank?
    return if receiver_currency.blank?

    unless receiver_currency_id == receiver_account.currency_id
      errors.add(
        :receiver_currency_id,
        "must match the receiver account currency"
      )
    end
  end


  # ==================================================
  # EXCHANGE RATE / TO CURRENCY VALIDATIONS
  # ==================================================

  def sender_rate_requires_to_currency
    rate_exists =
      sender_exchange_rate.present?

    currency_exists =
      sender_to_currency_id.present?


    if rate_exists && !currency_exists
      errors.add(
        :sender_to_currency_id,
        "must be selected when sender exchange rate is provided"
      )
    end


    if currency_exists && !rate_exists
      errors.add(
        :sender_exchange_rate,
        "must be provided when sender To Currency is selected"
      )
    end
  end


  def receiver_rate_requires_to_currency
    rate_exists =
      receiver_exchange_rate.present?

    currency_exists =
      receiver_to_currency_id.present?


    if rate_exists && !currency_exists
      errors.add(
        :receiver_to_currency_id,
        "must be selected when receiver exchange rate is provided"
      )
    end


    if currency_exists && !rate_exists
      errors.add(
        :receiver_exchange_rate,
        "must be provided when receiver To Currency is selected"
      )
    end
  end


  # ==================================================
  # RECEIVER CURRENCY VALIDATION
  # ==================================================

  def receiver_currency_matches_sender_conversion

    return if sender_currency.blank?
    return if receiver_currency.blank?


    # --------------------------------------------------
    # If sender exchange rate exists:
    #
    # Receiver currency MUST equal
    # Sender To Currency.
    # --------------------------------------------------

    if sender_exchange_rate.present?

      return if sender_to_currency_id.blank?

      unless receiver_currency_id == sender_to_currency_id

        errors.add(
          :receiver_currency_id,
          "must match the sender To Currency"
        )

      end

      return
    end


    # --------------------------------------------------
    # If sender exchange rate does NOT exist:
    #
    # Receiver currency MUST equal
    # Sender currency.
    # --------------------------------------------------

    unless receiver_currency_id == sender_currency_id

      errors.add(
        :receiver_currency_id,
        "must match the sender currency when no sender exchange rate is provided"
      )

    end
  end
end
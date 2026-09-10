class Xaccount < ApplicationRecord
  # ==================================================
  # ASSOCIATIONS
  # ==================================================

  belongs_to :currency
  belongs_to :organization

  has_many :xtransactions,
           dependent: :restrict_with_error

  has_many :sent_transfers,
           class_name: "Xtransfer",
           foreign_key: :sender_account_id,
           dependent: :restrict_with_error

  has_many :received_transfers,
           class_name: "Xtransfer",
           foreign_key: :receiver_account_id,
           dependent: :restrict_with_error

  has_many :seller_exchanges,
           class_name: "Exchange",
           foreign_key: :seller_account_id,
           dependent: :restrict_with_error

  has_many :buyer_exchanges,
           class_name: "Exchange",
           foreign_key: :buyer_account_id,
           dependent: :restrict_with_error

  has_many :sent_remittances,
           class_name: "Remittance",
           foreign_key: :sender_account_id,
           dependent: :restrict_with_error

  has_many :received_remittances,
           class_name: "Remittance",
           foreign_key: :receiver_account_id,
           dependent: :restrict_with_error

  has_many :sent_xpayments,
           class_name: "Xpayment",
           foreign_key: :sender_account_id,
           dependent: :restrict_with_error

  has_many :received_xpayments,
           class_name: "Xpayment",
           foreign_key: :receiver_account_id,
           dependent: :restrict_with_error


  # ==================================================
  # VALIDATIONS
  # ==================================================

  validates :number,
            presence: true

  validates :kind,
            presence: true

  validates :debit_amount,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validates :credit_amount,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validate :details_required_when_start_amount_changes

  before_save :sync_start_amount,
              if: :will_save_change_to_start_amount?


  # ==================================================
  # BALANCE
  # ==================================================

  # Debit increases the account balance.
  # Credit decreases the account balance.
  #
  # Example:
  #
  # debit_amount  = 10,000
  # credit_amount = 3,000
  #
  # balance = 7,000
  #
  def balance
    debit_amount.to_i - credit_amount.to_i
  end


  # ==================================================
  # DEBIT
  # ==================================================

  def debit!(value)
    value = value.to_i

    raise ArgumentError,
          "Debit amount must be greater than zero" if value <= 0

    update!(
      debit_amount: debit_amount.to_i + value
    )
  end


  # ==================================================
  # CREDIT
  # ==================================================

  def credit!(value)
    value = value.to_i

    raise ArgumentError,
          "Credit amount must be greater than zero" if value <= 0

    update!(
      credit_amount: credit_amount.to_i + value
    )
  end


  # ==================================================
  # BALANCE HELPERS
  # ==================================================

  def debit_total
    debit_amount.to_i
  end

  def credit_total
    credit_amount.to_i
  end


  # ==================================================
  # START AMOUNT
  # ==================================================

  # start_amount represents the opening balance.
  #
  # Positive opening balance:
  #   debit_amount = start_amount
  #   credit_amount = 0
  #
  # Negative opening balance:
  #   debit_amount = 0
  #   credit_amount = abs(start_amount)
  #
  def sync_start_amount
    self.date_change_start_amount = Date.current

    value = start_amount.to_i

    if value >= 0
      self.debit_amount = value
      self.credit_amount = 0
    else
      self.debit_amount = 0
      self.credit_amount = value.abs
    end
  end


  private

  def details_required_when_start_amount_changes
    if will_save_change_to_start_amount? &&
       details_of_change_start_amount.blank?

      errors.add(
        :details_of_change_start_amount,
        "must be provided when start amount is changed"
      )
    end
  end
end
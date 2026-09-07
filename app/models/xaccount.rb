class Xaccount < ApplicationRecord
  belongs_to :currency
  belongs_to :organization

  # KEEP only this one
  has_many :xtransactions, dependent: :restrict_with_error

  # REMOVE this duplicate line if it still exists:
  # has_many :xtransactions, as: :transactionable, dependent: :destroy

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

  validates :number, presence: true
  validates :kind, presence: true

  validate :details_required_when_start_amount_changes

  before_save :sync_amount_and_date, if: :start_amount_changed?

  private

  def details_required_when_start_amount_changes
    if start_amount_changed? && details_of_change_start_amount.blank?
      errors.add(:details_of_change_start_amount, "must be provided when start amount is changed")
    end
  end

  def sync_amount_and_date
    self.date_change_start_amount = Date.current
    self.amount = start_amount
  end
end
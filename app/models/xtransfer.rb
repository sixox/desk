class Xtransfer < ApplicationRecord
  belongs_to :sender_account,
             class_name: "Xaccount",
             foreign_key: :sender_account_id

  belongs_to :receiver_account,
             class_name: "Xaccount",
             foreign_key: :receiver_account_id

  belongs_to :sender_currency,
             class_name: "Currency"

  belongs_to :receiver_currency,
             class_name: "Currency"

  validates :sent_amount, presence: true
  validates :receive_amount, presence: true
  validates :exchange_rate, presence: true
  validates :status, presence: true
  validates :sender_currency_id, presence: true
  validates :receiver_currency_id, presence: true

  validate :sender_account_currency_matches
  validate :receiver_account_currency_matches

  scope :pending, -> { where(pending: true) }

  has_many :exchange_transfers, dependent: :destroy
  has_many :exchanges, through: :exchange_transfers

  has_many_attached :documents


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

  def sender_account_currency_matches
    return if sender_account.blank? || sender_currency.blank?

    return if sender_account.currency_id == sender_currency_id

    errors.add(
      :sender_currency,
      "must match the Sender Account currency (#{sender_account.currency.name})"
    )
  end

  def receiver_account_currency_matches
    return if receiver_account.blank? || receiver_currency.blank?

    return if receiver_account.currency_id == receiver_currency_id

    errors.add(
      :receiver_currency,
      "must match the Receiver Account currency (#{receiver_account.currency.name})"
    )
  end
end
class Remittance < ApplicationRecord
  belongs_to :sender_account,
             class_name: "Xaccount"

  belongs_to :receiver_account,
             class_name: "Xaccount"

  belongs_to :currency

  has_many :xtransactions,
           as: :transactionable,
           dependent: :destroy

  has_many_attached :documents

  validates :sent_amount, presence: true
  validates :received_amount, presence: true

  validate :sender_account_currency_matches
  validate :receiver_account_currency_matches

  private

  def sender_account_currency_matches
    return if sender_account.blank? || currency.blank?
    return if sender_account.currency_id == currency_id

    errors.add(
      :sender_account,
      "currency must match remittance currency (#{currency.name})"
    )
  end

  def receiver_account_currency_matches
    return if receiver_account.blank? || currency.blank?
    return if receiver_account.currency_id == currency_id

    errors.add(
      :receiver_account,
      "currency must match remittance currency (#{currency.name})"
    )
  end
end
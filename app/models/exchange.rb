class Exchange < ApplicationRecord
  belongs_to :seller_account,
             class_name: "Xaccount"

  belongs_to :buyer_account,
             class_name: "Xaccount"

  belongs_to :sell_currency,
             class_name: "Currency"

  belongs_to :buy_currency,
             class_name: "Currency"

  has_many :exchange_transfers, dependent: :destroy
  has_many :xtransfers, through: :exchange_transfers

  has_many_attached :documents

  enum kind: {
    cross_currency: 0,
    same_currency: 1,
    currency_exchange: 2
  }

  validates :sell_amount, presence: true
  validates :buy_amount, presence: true
  validates :exchange_rate, presence: true
  validates :kind, presence: true

  validate :seller_account_currency_matches
  validate :buyer_account_currency_matches

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

  def seller_account_currency_matches
    return if seller_account.blank? || sell_currency.blank?

    return if seller_account.currency_id == sell_currency_id

    errors.add(
      :sell_currency,
      "must match the Seller Account currency (#{seller_account.currency.name})"
    )
  end

  def buyer_account_currency_matches
    return if buyer_account.blank? || buy_currency.blank?

    return if buyer_account.currency_id == buy_currency_id

    errors.add(
      :buy_currency,
      "must match the Buyer Account currency (#{buyer_account.currency.name})"
    )
  end
end
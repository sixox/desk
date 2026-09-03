class Xaccount < ApplicationRecord
  belongs_to :currency
  belongs_to :organization

  has_many :credits,
  foreign_key: :xaccount_id,
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

  validates :number, presence: true
  validates :kind, presence: true
end
class Currency < ApplicationRecord
  has_many :xaccounts, dependent: :restrict_with_error

  has_many :sell_exchanges,
           class_name: "Exchange",
           foreign_key: :sell_currency_id,
           dependent: :restrict_with_error

  has_many :buy_exchanges,
           class_name: "Exchange",
           foreign_key: :buy_currency_id,
           dependent: :restrict_with_error
           
  has_many :sender_xtransfers,
           class_name: "Xtransfer",
           foreign_key: :sender_currency_id,
           dependent: :restrict_with_error

  has_many :sender_to_xtransfers,
           class_name: "Xtransfer",
           foreign_key: :sender_to_currency_id,
           dependent: :restrict_with_error

  has_many :receiver_xtransfers,
           class_name: "Xtransfer",
           foreign_key: :receiver_currency_id,
           dependent: :restrict_with_error

  has_many :receiver_to_xtransfers,
           class_name: "Xtransfer",
           foreign_key: :receiver_to_currency_id,
           dependent: :restrict_with_error

  has_many :xtransactions

  validates :name, presence: true
end



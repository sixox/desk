class ExchangeTransfer < ApplicationRecord
  belongs_to :exchange
  belongs_to :xtransfer

  validates :xtransfer_id, uniqueness: {
    scope: :exchange_id
  }
end
class RialReceipt < ApplicationRecord
  belongs_to :payment_order

  validates :payment_order, presence: true
  validates :in_words, :details, :receiver, :payment_date,  presence: true
end

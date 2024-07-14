class Sci < ApplicationRecord
  belongs_to :spi
  belongs_to :ballance
  belongs_to :user
  has_many :payment_orders

  has_one_attached :document
  validates :net_weight, :gross_weight, :total_price, :balance_payment, :number, :issue_date, presence: true

end

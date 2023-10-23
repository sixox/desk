class Spi < ApplicationRecord
  belongs_to :user
  belongs_to :ballance
  has_many :spis
  has_many :payment_orders

  
  has_one_attached :document

end

class Deposit < ApplicationRecord
  belongs_to :bank

  has_one_attached :document

end

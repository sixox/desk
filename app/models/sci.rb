class Sci < ApplicationRecord
  belongs_to :spi
  belongs_to :ballance
  belongs_to :user

  has_one_attached :document


end

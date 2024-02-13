class Price < ApplicationRecord
  belongs_to :user
  has_many :historical_prices, dependent: :destroy

  STATUSES = ['Available', 'PI Based', 'Aprox Price']


end

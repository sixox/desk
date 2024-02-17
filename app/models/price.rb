class Price < ApplicationRecord
  belongs_to :user
  has_many :historical_prices, dependent: :destroy

  STATUSES = ['Available', 'PI Based', 'Aprox Price']

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'refinery']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end


end

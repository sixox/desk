class HistoricalPrice < ApplicationRecord
  belongs_to :price
  belongs_to :user
end

class Booking < ApplicationRecord
  belongs_to :project
  has_one :project
end

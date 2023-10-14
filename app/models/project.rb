class Project < ApplicationRecord
	  has_one :pi
	  belongs_to :ci, optional: true
	  has_many :bookings
end

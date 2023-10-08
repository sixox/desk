class Project < ApplicationRecord
	  has_one :pi
	  belongs_to :ci
	  has_many :bookings

end

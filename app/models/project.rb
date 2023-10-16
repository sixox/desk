class Project < ApplicationRecord
	  has_one :pi
	  has_many :cis
	  has_many :bookings
end

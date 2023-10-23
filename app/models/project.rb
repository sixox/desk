class Project < ApplicationRecord
	has_one :pi
	has_many :cis
	has_many :bookings
	has_many :ballance_projects
	has_many :ballances, through: :ballance_projects
	has_many :payment_orders
end

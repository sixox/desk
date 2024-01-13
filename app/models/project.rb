class Project < ApplicationRecord
	has_one :pi
	has_many :cis
	has_many :bookings
	has_many :ballance_projects
	has_many :ballances, through: :ballance_projects
	has_many :payment_orders
	has_many :swifts




  def self.ransackable_attributes(auth_object = nil)
    ['name', 'number']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end


end

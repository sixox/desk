class Ballance < ApplicationRecord
	has_one :spi
	belongs_to :supplier
	has_many :scis
	has_many :ballance_projects
  	has_many :projects, through: :ballance_projects
  	has_many :payment_orders




  	def not_allocated_quantity
  		q = ballance_projects.sum(:quantity)
  		spi.quantity - q
  	end

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'number']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

end

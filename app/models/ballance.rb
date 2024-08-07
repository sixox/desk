class Ballance < ApplicationRecord
	has_one :spi
	belongs_to :supplier
	has_many :scis
	has_many :ballance_projects
  has_many :projects, through: :ballance_projects
  has_many :payment_orders
  validates :product, :name, presence: true

  validates :number, presence: true, format: { with: /\A14\d{2}-\d{3}\z/, message: "must be in the format '14xx-xxx'" }, uniqueness: true

  def remaining_quantity
    spi_quantity = self.spi&.quantity.to_i
    allocated_quantity = self.ballance_projects.sum(:quantity).to_i
    spi_quantity - allocated_quantity
  end

  def not_allocated_quantity
    return 0 unless spi
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

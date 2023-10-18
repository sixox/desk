class Ballance < ApplicationRecord
	has_one :spi
	belongs_to :supplier
	has_many :scis
	has_many :ballance_projects
  	has_many :projects, through: :ballance_projects
end

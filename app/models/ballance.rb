class Ballance < ApplicationRecord
	has_one :spi
	belongs_to :supplier
	has_many :scis
end

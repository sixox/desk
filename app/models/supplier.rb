class Supplier < ApplicationRecord
	belongs_to :user
	has_many :spis
	has_many :ballances
end

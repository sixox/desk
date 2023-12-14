class Bank < ApplicationRecord
	has_many :payment_orders
	has_many :swifts
end

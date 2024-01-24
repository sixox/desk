class Bank < ApplicationRecord
	has_many :payment_orders
	has_many :swifts
	has_many :deposits

	has_many :withdrawn_transfers, class_name: 'Transfer', foreign_key: 'withdraw_from'
  	has_many :deposited_transfers, class_name: 'Transfer', foreign_key: 'deposited_to'
end

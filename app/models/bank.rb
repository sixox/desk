class Bank < ApplicationRecord
	has_many :payment_orders
	has_many :swifts
	has_many :deposits
	has_many :accounts


	has_many :withdrawn_transfers, class_name: 'Transfer', foreign_key: 'withdraw_from'
	has_many :deposited_transfers, class_name: 'Transfer', foreign_key: 'deposited_to'

	def total_expected_balance
		unconfirmed_unrejected_swifts = swifts.where(confirmed: [nil, false], rejected: [nil, false])
		sum_unconfirmed_unrejected_swifts = 0

		unconfirmed_unrejected_swifts.each do |swift|
			if swift.currency == currency
				sum_unconfirmed_unrejected_swifts += swift.amount
			else
				a = swift.currency == "dollar" ? swift.amount * 3.67 : swift.amount / 3.67
				sum_unconfirmed_unrejected_swifts += a
			end
		end

		waiting_payment_orders = payment_orders.where(status: 'wait for payment')
		a = account_balance
		b = sum_unconfirmed_unrejected_swifts
		c = waiting_payment_orders.sum(:amount)

		a.to_i - c.to_i + b.to_i
	end



end

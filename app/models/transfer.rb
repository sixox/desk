class Transfer < ApplicationRecord
	belongs_to :withdraw_from_bank, class_name: 'Bank', foreign_key: 'withdraw_from'
	belongs_to :deposited_to_bank, class_name: 'Bank', foreign_key: 'deposited_to'
    has_many :transactions, as: :transactionable
    has_one_attached :document


	validates :withdraw_amount, :deposited_amount, presence: true
end

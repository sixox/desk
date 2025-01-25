require 'csv'

class Transaction < ApplicationRecord
  belongs_to :transactionable, polymorphic: true
  belongs_to :bank

  def self.to_csv
    attributes = %w[ID Bank Type Deposit Withdraw Balance_Before Balance_After Date]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.includes(:bank).find_each do |transaction|
        csv << [
          transaction.id,
          transaction.bank.name,
          transaction.transactionable_type == "PaymentOrder" ? "P.O #{transaction.transactionable_id}" : "#{transaction.transactionable_type} #{transaction.transactionable_id}",
          transaction.deposit_amount,
          transaction.withdrawal_amount,
          transaction.balance_before_transaction,
          transaction.balance_after_transaction,
          (transaction.created_at + 3.5.hours).strftime("%Y-%m-%d %H:%M:%S")
        ]
      end
    end
  end
end

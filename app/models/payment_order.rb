class PaymentOrder < ApplicationRecord
  belongs_to :user

  validates :reference, :amount, :from, :to, :receiver, 
            :receiver_account, :currency, :payment_type, 
            :status, :currency, presence: true

end

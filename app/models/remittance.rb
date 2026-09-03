class Remittance < ApplicationRecord
  belongs_to :sender_account,
             class_name: "Xaccount"

  belongs_to :receiver_account,
             class_name: "Xaccount"

  belongs_to :currency

  validates :sent_amount, presence: true
  validates :received_amount, presence: true
end
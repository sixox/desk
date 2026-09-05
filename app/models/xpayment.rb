class Xpayment < ApplicationRecord
  belongs_to :sender_account,
             class_name: "Xaccount"
  belongs_to :receiver_account,
             class_name: "Xaccount"
  belongs_to :currency
  has_many_attached :documents
end
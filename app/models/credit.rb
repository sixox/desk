class Credit < ApplicationRecord
  belongs_to :currency
  belongs_to :organization
  belongs_to :account, class_name: "Xaccount", foreign_key: :xaccount_id, optional: true
  validates :amount, presence: true
end
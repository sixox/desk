class Xtransaction < ApplicationRecord
  belongs_to :transactionable, polymorphic: true
  belongs_to :xaccount
  belongs_to :currency
end
class Transaction < ApplicationRecord
  belongs_to :transactionable, polymorphic: true
  belongs_to :bank
end

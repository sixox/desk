class RialReceipt < ApplicationRecord
  belongs_to :payment_order
end

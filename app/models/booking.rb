class Booking < ApplicationRecord
  belongs_to :project
  has_many :payment_orders

  LINE = ['HDS', 'hoopad','hormoz marin']
  FORWARDER = ['Daryabar', 'hormoz marin']
  CONTAINER_TYPE = ['20-foot', '40-foot']

  def empty
    return 0 if quantity.nil? || filled.nil?

    quantity - filled
  end

end

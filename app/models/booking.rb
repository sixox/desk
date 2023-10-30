class Booking < ApplicationRecord
  before_save :set_status

  belongs_to :project
  has_many :payment_orders

  LINE = ['HDS', 'hoopad','hormoz marin']
  FORWARDER = ['Daryabar', 'hormoz marin']
  CONTAINER_TYPE = ['20-foot', '40-foot']

  def empty
    return 0 if quantity.nil? || filled.nil?

    quantity - filled
  end

  def set_status
    if vessel_etd.present?
      self.status = "vessel ETD"
    elsif custom_submission_date.present?
      self.status = "custom submission"
    elsif custom_clearance.present?
      self.status = "custom clearance"
    elsif stuffing.present?
      self.status = "stuffing"
    elsif pick_up_date.present?
      self.status = "picked up"
    elsif factory_order_date.present?
      self.status = "factory order"
    else
      self.status = "not started"

    end
  end

end

class Booking < ApplicationRecord
  before_save :set_status

  belongs_to :project
  has_many :payment_orders
  has_one_attached :bl_draft
  has_one_attached :bl_dated
  has_one_attached :surrender
  has_many_attached :images
  has_one :release_request, dependent: :destroy



  validates :number, :pod, :container_type, :quantity, presence: true


  LINE = [
  'ABDIS MARINE',
  'ADMIRAL',
  'AMVAJE ZARIN',
  'ARTA',
  'ARTEMIS DARYA',
  'ARYA LAND',
  'ASL',
  'AVASH',
  'BLUE',
  'CORVET',
  'DATAM SEA ARVAND',
  'DARYA BAAR',
  'ECON',
  'ESPAD DARYA',
  'FARTAK',
  'HDS',
  'HORMOZ MARIN',
  'KALADARAN',
  'KUSHAN DARYA',
  'LOTUS',
  'MARITIME MAVEN MANAGEMENT',
  'NAVBAN DARYA',
  'NOVEL',
  'RADIAN DARYA',
  'RASHA',
  'SAHEL SANGI',
  'TIAM DARYA',
  'TUSHEHBAR'
]

FORWARDER = [
  'ABDIS MARINE',
  'ADMIRAL',
  'AMVAJE ZARIN',
  'ARTA',
  'ARTEMIS DARYA',
  'ARYA LAND',
  'AVASH',
  'BLUE',
  'CORVET',
  'DATAM SEA ARVAND',
  'DARYA BAAR',
  'ECON',
  'ESPAD DARYA',
  'FARTAK',
  'HORMOZ MARIN',
  'KALADARAN',
  'KUSHAN DARYA',
  'LOTUS',
  'MARITIME MAVEN MANAGEMENT',
  'NAVBAN DARYA',
  'NOVEL',
  'RADIAN DARYA',
  'RASHA',
  'SAHEL SANGI',
  'TIAM DARYA',
  'TUSHEHBAR'
]

  CONTAINER_TYPE = ['20-foot', '40-foot']

  def empty
    return 0 if quantity.nil? || filled.nil?

    quantity - filled
  end

  def set_status
    if vessel_eta.present?
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

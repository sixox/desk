class Pi < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  belongs_to :project
  belongs_to :ci, optional: true

  has_one_attached :document


  PRODUCT = ['bitumen 60/70', 'bitumen 80/100']
  CURRENCY = ['dollar', 'dirham']
  PAYMENT_TERM = ['30% advance', '20% advance']
  POL = ['IRAN', 'UAE', 'BND/IRAN']
  PACKING_TYPE = ['180kg new drums', 'Jumbo', '180kg second hand drums', 'bulk']
  SELLER = ['ZigguratOil', 'WhiteSands']

end

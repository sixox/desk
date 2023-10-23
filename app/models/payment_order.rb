class PaymentOrder < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :sci, optional: true
  belongs_to :spi, optional: true
  belongs_to :ballance, optional: true
  belongs_to :booking, optional: true

  has_one_attached :document








end

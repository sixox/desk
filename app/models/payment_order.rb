class PaymentOrder < ApplicationRecord
  before_save :set_status

  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :sci, optional: true
  belongs_to :spi, optional: true
  belongs_to :ballance, optional: true
  belongs_to :booking, optional: true

  has_one_attached :document
  has_one_attached :receipt
  has_many :comments, as: :commentable, dependent: :destroy


  validate :coo_confirmation_requires_from




  def set_status
    if !ceo_confirm
      self.status = "wait for confirm"
    else
      if !receipt.attached?
        self.status = "wait for payment"
      else
        if delivery_confirm
          self.status = "delivered"
        else
          self.status = "wait for delivery"
        end
      end
    end
  end

  private

  def coo_confirmation_requires_from
    if coo_confirm && from.blank?
      errors.add(:from, "must be present before COO confirmation")
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ['first_name', 'last_name']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end








end

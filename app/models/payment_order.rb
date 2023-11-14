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

  scope :filtered_by_role_and_dep_confirm, ->(current_user) {
    where(department_confirm: [nil, false])
    .joins(:user)
    .where(users: { role: current_user.role })
  }

  scope :filtered_by_role, ->(current_user) {
    joins(:user)
    .where(users: { role: current_user.role })
  }

  scope :not_confirmed_by_ceo_but_by_coo_and_accounting, -> {
    where(ceo_confirm: [nil, false])
    .where(coo_confirm: true)
    .where(accounting_confirm: true)
    .where(department_confirm: true)

  }

  scope :not_confirmed_by_coo, -> {
    where(coo_confirm: [nil, false])
  }

  scope :not_confirmed_by_accounting, -> {
    where(accounting_confirm: [nil, false])
    .where(department_confirm: true)
    .where(coo_confirm: true)
  }




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

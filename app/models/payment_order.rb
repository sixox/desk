class PaymentOrder < ApplicationRecord
  before_save :set_status

  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :sci, optional: true
  belongs_to :spi, optional: true
  belongs_to :ballance, optional: true
  belongs_to :booking, optional: true
  belongs_to :bank, optional: true


  has_one_attached :document
  has_one_attached :receipt
  has_many :comments, as: :commentable, dependent: :destroy

  attr_accessor :skip_coo_confirmation_requirement

  validates :currency, presence: true


  # validate :coo_confirmation_requires_bank, unless: :skip_coo_confirmation_requirement

  scope :filtered_by_role_and_dep_confirm, ->(current_user) {
    where(department_confirm: [nil, false])
    .where(rejected_at: [nil, false])
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
    .where(rejected_at: [nil, false])


  }

  scope :not_confirmed_by_coo, -> {
    where(coo_confirm: [nil, false])
    .where(rejected_at: [nil, false])

  }

  scope :not_confirmed_by_accounting, -> {
    where(accounting_confirm: [nil, false])
    .where(department_confirm: true)
    .where(coo_confirm: true)
    .where(rejected_at: [nil, false])

  }

  scope :by_month, ->(selected_date) {
    where(created_at: selected_date.beginning_of_month..selected_date.end_of_month) if selected_date.present?
  }

  scope :by_status_and_currency, ->(status, currency) {
    query = where(status: status)
    query = query.where(currency: currency) if currency.present?
    query
  }

  scope :paid_by_currency, ->(selected_date = nil, currency) {
    by_status_and_currency(['delivered', 'wait for delivery'], currency)
    .by_month(selected_date)
  }

  scope :filtered_orders, ->(status, currency, selected_date) {
    by_status_and_currency(status, currency)
    .by_month(selected_date)
  }

  scope :by_status, ->(status) { where(status: status) }







  def set_status
    if !rejected_at
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
    else
      self.status = "rejected"
    end
  end

  private

  # def coo_confirmation_requires_bank
  #   if coo_confirm && bank.blank? 
  #     errors.add(:bank, "must be present before COO confirmation")
  #   end
  # end





  def self.ransackable_attributes(auth_object = nil)
    ['first_name', 'last_name']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end








end

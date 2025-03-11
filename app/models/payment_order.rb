require 'csv'

class PaymentOrder < ApplicationRecord
  before_save :handle_secret_confirmations
  before_save :set_status

  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :sci, optional: true
  belongs_to :spi, optional: true
  belongs_to :ballance, optional: true
  belongs_to :booking, optional: true
  belongs_to :bank, optional: true
  has_one :rial_receipt, dependent: :destroy



  has_one_attached :document
  has_one_attached :receipt
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :transactions, as: :transactionable


  attr_accessor :skip_coo_confirmation_requirement

  validates :currency, presence: true
  validates :amount, presence: true



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

  scope :not_confirmed_by_cob_but_by_ceo_and_accounting, -> {
    where(cob_confirm: [nil, false])
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
      if !cob_confirm || !ceo_confirm
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

  def self.ransackable_attributes(auth_object = nil)
    ['id', 'details', 'amount'] # Attributes of PaymentOrder to search on
  end

  def self.ransackable_associations(auth_object = nil)
    ['project', 'ballance'] # Associations to allow search on
  end


  def self.to_csv
    attributes = [
      "reference", "amount", "from", "to", "receiver", "receiver_account", "details",
      "exchange_rate", "exchange_amount", "have_factor", "inserted", "payment_type",
      "department_confirm", "accounting_confirm", "ceo_confirm", "status", "currency",
      "created_at", "is_rahkarsazan", "coo_confirm", "delivery_confirm", "ceo_confirmed_at",
      "coo_confirmed_at", "department_confirmed_at", "accounting_confirmed_at", "delivered_at",
      "reject_by", "rejected_at", "bank", "hamed_confirm", "hamed_confirmed_at",
      "shaghayegh_confirm", "cob_confirm", "cob_confirmed_at", 
      "project", "supplier_ci", "supplier_pi", "inventory", "booking", "user"
    ]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.find_each do |payment_order|
        csv << [
          payment_order.reference,
          payment_order.amount,
          payment_order.from,
          payment_order.to,
          payment_order.receiver,
          payment_order.receiver_account,
          payment_order.details,
          payment_order.exchange_rate,
          payment_order.exchange_amount,
          payment_order.have_factor,
          payment_order.inserted,
          payment_order.payment_type,
          payment_order.department_confirm,
          payment_order.accounting_confirm,
          payment_order.ceo_confirm,
          payment_order.status,
          payment_order.currency,
          payment_order.created_at,
          payment_order.is_rahkarsazan,
          payment_order.coo_confirm,
          payment_order.delivery_confirm,
          payment_order.ceo_confirmed_at,
          payment_order.coo_confirmed_at,
          payment_order.department_confirmed_at,
          payment_order.accounting_confirmed_at,
          payment_order.delivered_at,
          payment_order.reject_by,
          payment_order.rejected_at,
          payment_order.bank&.name,
          payment_order.hamed_confirm,
          payment_order.hamed_confirmed_at,
          payment_order.shaghayegh_confirm,
          payment_order.cob_confirm,
          payment_order.cob_confirmed_at,
          payment_order.project&.number,
          payment_order.sci&.number,
          payment_order.spi&.number,
          payment_order.ballance&.number,
          payment_order.booking&.number,
          payment_order.user&.name
        ]
      end
    end
  end

  private

  # def coo_confirmation_requires_bank
  #   if coo_confirm && bank.blank? 
  #     errors.add(:bank, "must be present before COO confirmation")
  #   end
  # end

  def handle_secret_confirmations
    return unless mahramane?

    # Ensure all required confirmations are set to true
    self.coo_confirm = true
    self.department_confirm = true
    self.accounting_confirm = true

    # Ensure timestamps are set only if not already set
    self.coo_confirmed_at ||= Time.now
    self.department_confirmed_at ||= Time.now
    self.accounting_confirmed_at ||= Time.now
  end



 








end

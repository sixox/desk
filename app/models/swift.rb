class Swift < ApplicationRecord
  belongs_to :bank
  belongs_to :ci, optional: true
  belongs_to :project, optional: true
  has_many :transactions, as: :transactionable


  has_many_attached :documents

  validates :currency, presence: true
  validates :amount, presence: true
  validate :documents_present

  scope :with_bank_and_ci, -> { includes(:bank, :ci) }

  def self.ransackable_attributes(auth_object = nil)
    super + ['amount', 'from'] # Attributes of Swift to search on
  end

  def self.ransackable_associations(auth_object = nil)
    super + ['project'] # Associations to allow search on
  end

  # Optional: Add a virtual attribute for partial search on `amount` (if needed)
  def amount_as_string
    amount.to_s
  end

  def self.ransackable_scopes(auth_object = nil)
    super + %w[amount_as_string]
  end

  
  private

  def documents_present
    errors.add(:documents, "must be attached") unless documents.attached?
  end
end

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
    super + ['amount', 'from', 'project_number']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
  
  private

  def documents_present
    errors.add(:documents, "must be attached") unless documents.attached?
  end
end

class Organization < ApplicationRecord
  # ==========================================================
  # CONSTANTS
  # ==========================================================

  KINDS = [
    "Company",
    "Bank",
    "Person",
    "Other"
  ].freeze


  # ==========================================================
  # ASSOCIATIONS
  # ==========================================================

  has_many :xaccounts, dependent: :restrict_with_error


  # ==========================================================
  # NESTED ATTRIBUTES
  # ==========================================================

  accepts_nested_attributes_for :xaccounts,
                                allow_destroy: true,
                                reject_if: ->(attrs) {
                                  attrs.slice("number", "kind", "currency_id").values.all?(&:blank?)
                                }


  # ==========================================================
  # VALIDATIONS
  # ==========================================================

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }, allow_blank: true
end
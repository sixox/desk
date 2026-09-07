class Organization < ApplicationRecord
  has_many :xaccounts, dependent: :restrict_with_error

  accepts_nested_attributes_for :xaccounts,
                                allow_destroy: true,
                                reject_if: ->(attrs) {
                                  attrs.slice("number", "kind", "currency_id").values.all?(&:blank?)
                                }

  validates :name, presence: true
end
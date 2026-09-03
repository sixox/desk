class Organization < ApplicationRecord
  has_many :xaccounts, dependent: :restrict_with_error
  has_many :credits, dependent: :restrict_with_error

  validates :name, presence: true
end
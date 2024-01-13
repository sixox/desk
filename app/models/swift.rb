class Swift < ApplicationRecord
  belongs_to :bank
  belongs_to :ci, optional: true
  belongs_to :project, optional: true

  has_many_attached :documents


  scope :with_bank_and_ci, -> { includes(:bank, :ci) }

end
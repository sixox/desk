class Deposit < ApplicationRecord
  belongs_to :bank

  has_one_attached :document
  validate :document_presence

  private

  def document_presence
    errors.add(:document, "must be attached") unless document.attached?
  end

end

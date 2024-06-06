class Ci < ApplicationRecord
  belongs_to :pi
  belongs_to :project
  belongs_to :user
  has_one :swift
  has_one :generated_document
  has_one_attached :document
  belongs_to :account, optional: true
  validates :net_weight, :gross_weight, :total_price, :balance_payment, :number, :issue_date, :advance_payment, presence: true

  validate :document_attached

  private

  def document_attached
    errors.add(:document, "must be attached") unless document.attached?
  end

end

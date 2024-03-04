class Account < ApplicationRecord
  belongs_to :bank
  has_many :pis
  has_many :cis

  validates :bank, presence: true


  def display_name_with_bank
    "#{name} - #{bank.name}"
  end
end

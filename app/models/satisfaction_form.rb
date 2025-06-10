class SatisfactionForm < ApplicationRecord
  belongs_to :user
  belongs_to :satisfaction
  
  # Validation for answer, ensuring it is between 1 and 6
  validates :answer, presence: true
end

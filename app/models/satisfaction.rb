class Satisfaction < ApplicationRecord
  has_many :satisfaction_forms, dependent: :destroy
  
  validates :category, presence: true
  validates :question, presence: true
end

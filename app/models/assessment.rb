class Assessment < ApplicationRecord
  has_many :assessment_forms, dependent: :destroy

  validates :category, :criterion, :definition, :title, presence: true
  validates :category_point, numericality: { only_integer: true }

  scope :management, -> { where(title: "management") }
  scope :superviser, -> { where(title: "superviser") }
  scope :employee, -> { where(title: "employee") 




end

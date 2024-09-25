class Assessment < ApplicationRecord
  has_many :assessment_forms, dependent: :destroy

  validates :category, :criterion, :definition, :title, presence: true
  validates :category_point, numericality: { only_integer: true }
end

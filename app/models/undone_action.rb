class UndoneAction < ApplicationRecord
  belongs_to :quarterly_evaluation

  attr_accessor :review_mode

  validates :weight, presence: true, inclusion: { in: [1, 2, 3] }, if: :review_mode?
  validates :point, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 }, if: :review_mode?

  private

  def review_mode?
    review_mode || quarterly_evaluation&.review_mode
  end
  
end

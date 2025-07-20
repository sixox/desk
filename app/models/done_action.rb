class DoneAction < ApplicationRecord
  belongs_to :result
  belongs_to :quarterly_evaluation

  delegate :review_mode, to: :quarterly_evaluation, allow_nil: true

  validates :weight, presence: true, inclusion: { in: [0, 1, 2, 3] }, if: :review_mode?
  validates :point, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 }, if: :review_mode?

  private

  def review_mode?
    review_mode == true
  end
end

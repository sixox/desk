class UndoneAction < ApplicationRecord
  belongs_to :result
  belongs_to :quarterly_evaluation

  attr_accessor :review_mode

 

  private

  def review_mode?
    review_mode || quarterly_evaluation&.review_mode
  end
  
end

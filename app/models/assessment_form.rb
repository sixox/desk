class AssessmentForm < ApplicationRecord
  belongs_to :assessment
  belongs_to :user # for the `user` attribute (the form is about this user)
  belongs_to :filler, class_name: 'User' # for the `filler` (who is filling the form)

  # validates :score, numericality: { only_integer: true, in: 1..10 }
  # validates :weight, numericality: { only_integer: true, in: 1..3 }

  # before_save :calculate_total_score

  # private

  # def calculate_total_score
  #   self.total_score = score * weight
  # end
end

class AssessmentForm < ApplicationRecord
  belongs_to :assessment
  belongs_to :user # for the `user` attribute (the form is about this user)
  belongs_to :filler, class_name: 'User' # for the `filler` (who is filling the form)

  # Scope to filter assessment forms by user and filler
  scope :by_user_and_filler, -> (user, filler) { where(user_id: user.id, filler_id: filler.id) }

  # Validation for score and weight
  validates :score, presence: true, numericality: { only_integer: true, in: 1..10 }
  validates :weight, presence: true, numericality: { only_integer: true, in: 1..3 }


  # Before save callback to calculate total score
  # before_save :calculate_total_score

  # Class method to get unique users associated with a given filler
  def self.unique_users_for_filler(filler, year, period)
    where(filler_id: filler.id, year: year, period: period).select(:user_id).distinct.map { |af| af.user }
  end
  
  def self.unique_fillers(year, period)
    # Select distinct filler_id and map to the User model
    where.not(filler_id: nil).where(year: year, period: period).select(:filler_id).distinct.map { |af| af.filler }
  end

  private

  # Method to calculate the total score
  def calculate_total_score
    self.total_score = score * weight
  end
end

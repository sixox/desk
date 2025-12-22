class RemoteDay < ApplicationRecord
  belongs_to :user

  validates :date, presence: true
  before_validation :default_confirmed

  # alias note <-> text for easier usage
  def note
    self.text
  end

  def note=(val)
    self.text = val
  end

  private

  def default_confirmed
    self.confirmed = true if confirmed.nil?
  end

end

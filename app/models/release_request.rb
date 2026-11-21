class ReleaseRequest < ApplicationRecord
  belongs_to :booking

  has_one :project, through: :booking
  has_one :customer, through: :project, source: :pi

  validates :booking_id, uniqueness: {
    message: "already has a release request"
  }
end
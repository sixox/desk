class ReleaseRequest < ApplicationRecord
  belongs_to :booking
  has_one :project, through: :booking
  has_one :customer, through: :project, source: :pi

 
end

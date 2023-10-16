class Ci < ApplicationRecord
  belongs_to :pi
  belongs_to :project
  belongs_to :user
  
  has_one_attached :document

end

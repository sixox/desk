class Pi < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  belongs_to :project
  belongs_to :ci

end

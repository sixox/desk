class Swift < ApplicationRecord
  belongs_to :bank
  belongs_to :ci
  has_many_attached :documents
end
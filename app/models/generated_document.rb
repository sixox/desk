class GeneratedDocument < ApplicationRecord
  belongs_to :user
  belongs_to :pi, optional: true
  belongs_to :ci, optional: true

  has_one_attached :file

end

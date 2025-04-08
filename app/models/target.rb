class Target < ApplicationRecord
  belongs_to :kpi_list
  has_many :results, dependent: :destroy

  # validates :description, presence: true
end

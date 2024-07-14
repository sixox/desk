class BallanceProject < ApplicationRecord
  belongs_to :ballance
  belongs_to :project

  validates :project_id, presence: true
  validates :ballance_id, presence: true
  validates :quantity, presence: true



end

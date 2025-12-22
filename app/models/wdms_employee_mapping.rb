class WdmsEmployeeMapping < ApplicationRecord
  belongs_to :user
  validates :emp_code, presence: true
end

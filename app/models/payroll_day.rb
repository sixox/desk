class PayrollDay < ApplicationRecord
  belongs_to :payroll_month

  validates :day_on, presence: true
end

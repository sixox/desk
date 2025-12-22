# app/models/salary_profile.rb
class SalaryProfile < ApplicationRecord
  belongs_to :user

  # Enum for payment type:
  # :hourly        -> hourly-paid (non-fixed) employees (pay varies with hours worked)
  # :fixed         -> fixed salary employees (no overtime/underwork calculations)
  # :fixed_with_overtime -> fixed salary but eligible for overtime/absence adjustments
  enum pay_type: { hourly: 0, fixed: 1, fixed_with_overtime: 2 }

  # Validate presence of total salary for calculations

  # (Other allowance fields like base_salary, housing_allowance, etc., are assumed to be present as columns)
end

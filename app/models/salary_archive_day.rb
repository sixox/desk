class SalaryArchiveDay < ApplicationRecord
  belongs_to :salary_archive

  def work_minutes_final
    work_minutes.to_i + manual_adjust_minutes.to_i
  end
end

# app/jobs/generate_archives_job.rb
class GenerateArchivesJob < ApplicationJob
  queue_as :default

  def perform(shamsi_month_id)
    month = ShamsiMonth.find(shamsi_month_id)

    # فقط کاربرانی که salary_profile دارند
    User.joins(:salary_profile).find_each do |user|
      SalaryArchiveBuilder
        .new(user: user, shamsi_month: month)
        .build!
    end
  end
end

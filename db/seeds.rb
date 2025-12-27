# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)


questions = [
  "شفافیت در اطلاع رسانی به سهامداران",
  "میزان سوددهی شرکت طی دوره اخیر",
  "دسترسی به گزارش های مالی و عملکردی",
  "نحوه برگزاری جلسات هیئت مدیره و مجمع عمومی",
  "ارتباط و پاسخگویی و گزارش دهی مدیران ارشد و میانی",
  "عملکرد هیئت مدیره",
  "تقویت و توسعه حکمرانی شرکتی",
  "پاسخگویی به سوالات و انتقادات",
  "مدیریت برند: خوشنامی - اعتبار - رضایت مشتریان - رضایت تامین کنندگان",
"نظر شما مهمترین اقدام برای بهبود رضایت سهامداران"
]

questions.each_with_index do |text, i|
  StakeholderSurvey.find_or_create_by!(
    question_text: text,
    position: i + 1
  )
end



year = 1403
period = 3
user_ids = [18, 19, 20]

users = User.where(id: user_ids)
surveys = StakeholderSurvey.order(:position)

users.each do |user|
  surveys.each do |survey|
    next if StakeholderSurveyForm.exists?(user: user, stakeholder_survey: survey, year: year, period: period)

    StakeholderSurveyForm.create!(
      {
        user: user,
        stakeholder_survey: survey,
        year: year,
        period: period,
        answer: nil,
        feedback: nil
      }
      
    )
  end

end





year = 1404
period = 3

  Satisfaction.find_each do |satisfaction|
      User.find_each do |user|
        # Skip if already exists
        next if SatisfactionForm.exists?(user: user, satisfaction: satisfaction, year: year, period: period)

        SatisfactionForm.create!(
          user: user,
          satisfaction: satisfaction,
          year: year,
          period: period
        )
      end
    end



    u = 3
f = 1
Assessment.employee.each do |m|
  a = AssessmentForm.new
  a.assessment = m
  a.user_id = u
  a.filler_id = f
  a.year = 1404
  a.period = 3
  a.save(validate: false)
end





Assessment.superviser.each do |m|
  a = AssessmentForm.new
  a.assessment = m
  a.user_id = u
  a.filler_id = f
  a.year = 1404
  a.period = 3
  a.save(validate: false)
end

Assessment.management.each do |m|
  a = AssessmentForm.new
  a.assessment = m
  a.user_id = u
  a.filler_id = f
  a.year = 1404
  a.period = 3
  a.save(validate: false)
end



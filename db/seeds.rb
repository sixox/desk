# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)


# questions = [
#   "شفافیت در اطلاع رسانی به سهامداران",
#   "میزان سوددهی شرکت طی دوره اخیر",
#   "دسترسی به گزارش های مالی و عملکردی",
#   "نحوه برگزاری جلسات هیئت مدیره و مجمع عمومی",
#   "ارتباط و پاسخگویی و گزارش دهی مدیران ارشد و میانی",
#   "عملکرد هیئت مدیره",
#   "تقویت و توسعه حکمرانی شرکتی",
#   "پاسخگویی به سوالات و انتقادات",
#   "مدیریت برند: خوشنامی - اعتبار - رضایت مشتریان - رضایت تامین کنندگان",
# "نظر شما مهمترین اقدام برای بهبود رضایت سهامداران"
# ]

# questions.each_with_index do |text, i|
#   StakeholderSurvey.find_or_create_by!(
#     question_text: text,
#     position: i + 1
#   )
# end



# year = 1403
# period = 3
# user_ids = [18, 19, 20]

# users = User.where(id: user_ids)
# surveys = StakeholderSurvey.order(:position)

# users.each do |user|
#   surveys.each do |survey|
#     next if StakeholderSurveyForm.exists?(user: user, stakeholder_survey: survey, year: year, period: period)

#     StakeholderSurveyForm.create!(
#       {
#         user: user,
#         stakeholder_survey: survey,
#         year: year,
#         period: period,
#         answer: nil,
#         feedback: nil
#       }

#     )
#   end

# end





# year = 1404
# period = 3

#   Satisfaction.find_each do |satisfaction|
#       User.find_each do |user|
#         # Skip if already exists
#         next if SatisfactionForm.exists?(user: user, satisfaction: satisfaction, year: year, period: period)

#         SatisfactionForm.create!(
#           user: user,
#           satisfaction: satisfaction,
#           year: year,
#           period: period
#         )
#       end
#     end



#     u = 3
# f = 1
# Assessment.employee.each do |m|
#   a = AssessmentForm.new
#   a.assessment = m
#   a.user_id = u
#   a.filler_id = f
#   a.year = 1404
#   a.period = 3
#   a.save(validate: false)
# end





# Assessment.superviser.each do |m|
#   a = AssessmentForm.new
#   a.assessment = m
#   a.user_id = u
#   a.filler_id = f
#   a.year = 1404
#   a.period = 3
#   a.save(validate: false)
# end

# Assessment.management.each do |m|
#   a = AssessmentForm.new
#   a.assessment = m
#   a.user_id = u
#   a.filler_id = f
#   a.year = 1404
#   a.period = 3
#   a.save(validate: false)
# end


# --------------------------------------------------
# Xtransfer seed
# --------------------------------------------------

# --------------------------------------------------
# Xtransfer seed
# --------------------------------------------------

puts "Clearing existing Xtransfer data..."

ActiveRecord::Base.transaction do
  ExchangeTransfer.delete_all if defined?(ExchangeTransfer)
  Xtransfer.delete_all

  accounts = Xaccount.includes(:currency, :organization).to_a

  if accounts.size < 4
    raise "Need at least 4 existing Xaccounts to seed Xtransfers."
  end

  # --------------------------------------------------
  # Find accounts with different currencies
  # --------------------------------------------------

  account_pairs = []

  accounts.each do |sender|
    receiver = accounts.find do |account|
      account.id != sender.id &&
        account.currency_id != sender.currency_id
    end

    account_pairs << [sender, receiver] if receiver
  end

  if account_pairs.empty?
    raise "Need at least two Xaccounts with different currencies."
  end

  # Use up to 5 different sender/receiver combinations
  account_pairs = account_pairs.first(5)

  # --------------------------------------------------
  # Conversion examples
  # --------------------------------------------------

  examples = [
    {
      sender_amount: 1000,
      sender_rate: 3.67,
      receiver_rate: 3.863157895,
      sender_charge: 0,
      receiver_charge: 0,
      status: "completed",
      pending: false
    },
    {
      sender_amount: 2500,
      sender_rate: 1.08,
      receiver_rate: 1.10,
      sender_charge: 1.5,
      receiver_charge: 0,
      status: "completed",
      pending: false
    },
    {
      sender_amount: 5000,
      sender_rate: 0.79,
      receiver_rate: 0.80,
      sender_charge: 0,
      receiver_charge: 1,
      status: "pending",
      pending: true
    },
    {
      sender_amount: 1200,
      sender_rate: 7.15,
      receiver_rate: 7.20,
      sender_charge: 0.5,
      receiver_charge: 0.5,
      status: "completed",
      pending: false
    },
    {
      sender_amount: 8000,
      sender_rate: 3.67,
      receiver_rate: 3.85,
      sender_charge: 0,
      receiver_charge: 0.75,
      status: "completed",
      pending: false
    }
  ]

  # --------------------------------------------------
  # Create transfers
  # --------------------------------------------------

  account_pairs.each_with_index do |(sender_account, receiver_account), index|

    data = examples[index]

    sender_amount = data[:sender_amount].to_d
    sender_rate = data[:sender_rate].to_d
    receiver_rate = data[:receiver_rate].to_d

    # Sender:
    # sender_amount × sender_rate = sender_amount_to
    sender_amount_to = sender_amount * sender_rate

    # Receiver amount is exactly the sender conversion result
    receiver_amount = sender_amount_to

    # Receiver:
    # receiver_amount ÷ receiver_rate = receiver_amount_to
    receiver_amount_to = receiver_amount / receiver_rate

    sender_charge = data[:sender_charge].to_d
    receiver_charge = data[:receiver_charge].to_d

    sender_total =
      sender_amount + (sender_amount * sender_charge / 100)

    receiver_total =
      receiver_amount + (receiver_amount * receiver_charge / 100)

    Xtransfer.create!(
      sender_account: sender_account,
      receiver_account: receiver_account,

      sender_currency: sender_account.currency,
      receiver_currency: receiver_account.currency,

      # Destination currencies are the opposite account currencies
      sender_to_currency: receiver_account.currency,
      receiver_to_currency: sender_account.currency,

      sender_amount: sender_amount,
      sender_exchange_rate: sender_rate,
      sender_amount_to: sender_amount_to,

      receiver_amount: receiver_amount,
      receiver_exchange_rate: receiver_rate,
      receiver_amount_to: receiver_amount_to,

      sender_charge: sender_charge,
      receiver_charge: receiver_charge,

      sender_total: sender_total,
      receiver_total: receiver_total,

      status: data[:status],
      pending: data[:pending]
    )
  end
end

puts "----------------------------------------"
puts "Xtransfer seed completed!"
puts "Xtransfers: #{Xtransfer.count}"
puts "----------------------------------------"
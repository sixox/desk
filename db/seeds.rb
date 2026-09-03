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


# db/seeds.rb

puts "Cleaning accounting test data..."

ExchangeTransfer.delete_all
Exchange.delete_all
Remittance.delete_all
Xpayment.delete_all
Xtransfer.delete_all
Credit.delete_all
Xaccount.delete_all
Organization.delete_all
Currency.delete_all

puts "Creating currencies..."

usd = Currency.create!(name: "USD")
eur = Currency.create!(name: "EUR")
irr = Currency.create!(name: "IRR")
gbp = Currency.create!(name: "GBP")

currencies = [usd, eur, irr, gbp]

puts "Creating organizations..."

organizations = [
  Organization.create!(
    name: "Alpha Trading",
    kind: "Company",
    start_amount: 50_000_000_000,
    date_change_start_amount: Date.current - 1.year,
    details_of_change_start_amount: "Initial company balance"
    ),

  Organization.create!(
    name: "Beta Holdings",
    kind: "Company",
    start_amount: 30_000_000_000,
    date_change_start_amount: Date.current - 8.months,
    details_of_change_start_amount: "Capital increase"
    ),

  Organization.create!(
    name: "Gamma Services",
    kind: "Business",
    start_amount: 15_000_000_000,
    date_change_start_amount: Date.current - 6.months,
    details_of_change_start_amount: "Initial balance"
    ),

  Organization.create!(
    name: "Delta International",
    kind: "Organization",
    start_amount: 100_000_000_000,
    date_change_start_amount: Date.current - 2.years,
    details_of_change_start_amount: "Opening balance"
    )
]

puts "Creating accounts..."

accounts = []

organizations.each do |organization|
  currencies.sample(rand(2..4)).each do |currency|
    accounts << Xaccount.create!(
      number: Faker::Bank.account_number(digits: 16),
      currency: currency,
      kind: ["Bank", "Cash", "Current", "Savings"].sample,
      organization: organization
      )
  end
end

puts "Created #{accounts.count} accounts."

puts "Creating credits..."

50.times do
  account = accounts.sample

  Credit.create!(
    currency: account.currency,
    amount: rand(100_000..5_000_000_000),
    organization: account.organization,
    xaccount_id: account.id
    )
end

puts "Created #{Credit.count} credits."

puts "Creating transfers..."

30.times do
  sender = accounts.sample
  receiver = accounts.reject { |account| account.id == sender.id }.sample

  sender_currency = sender.currency
  receiver_currency = receiver.currency

  sent_amount = rand(100_000..5_000_000_000)

  exchange_rate =
  if sender_currency.id == receiver_currency.id
    1.0
  else
    rand(0.5..500.0).round(4)
  end

  receive_amount = (sent_amount * exchange_rate).round
  pending = [true, false].sample

  Xtransfer.create!(
    sender_account: sender,
    receiver_account: receiver,
    sender_currency: sender_currency,
    receiver_currency: receiver_currency,
    sent_amount: sent_amount,
    receive_amount: receive_amount,
    exchange_rate: exchange_rate,
    wage: rand(0..50_000_000),
    status: pending ? "pending" : ["completed", "completed", "confirmed"].sample,
    pending: pending,
    pending_set_time: pending ? Faker::Time.between(
      from: 30.days.ago,
      to: Time.current
      ) : nil
    )
end

puts "Created #{Xtransfer.count} transfers."

puts
puts "================================"
puts "Seed completed"
puts "================================"
puts "Currencies:     #{Currency.count}"
puts "Organizations:  #{Organization.count}"
puts "Accounts:       #{Xaccount.count}"
puts "Credits:        #{Credit.count}"
puts "Transfers:      #{Xtransfer.count}"
puts "================================"



puts "Creating exchanges..."

50.times do
  kind = Exchange.kinds.keys.sample

  case kind

  when "same_currency"
    # Seller and buyer must have the same currency
    available_currencies = currencies.select do |currency|
      accounts.count { |account| account.currency_id == currency.id } >= 2
    end

    currency = available_currencies.sample

    same_currency_accounts =
    accounts.select do |account|
      account.currency_id == currency.id
    end

    seller = same_currency_accounts.sample

    buyer =
    same_currency_accounts
    .reject { |account| account.id == seller.id }
    .sample

    sell_currency = currency
    buy_currency = currency
    exchange_rate = 1.0


  when "cross_currency", "currency_exchange"
    # Seller account currency must match sell_currency
    seller = accounts.sample
    sell_currency = seller.currency

    # Buyer account currency must match buy_currency
    different_currency_accounts =
    accounts
    .reject do |account|
      account.id == seller.id ||
      account.currency_id == sell_currency.id
    end

    buyer = different_currency_accounts.sample

    # Safety fallback
    next if buyer.nil?

    buy_currency = buyer.currency
    exchange_rate = rand(0.5..500.0).round(5)
  end


  sell_amount = rand(100_000..5_000_000_000)
  buy_amount = (sell_amount * exchange_rate).round

  pending = [true, false].sample


  exchange = Exchange.create!(
    seller_account: seller,
    buyer_account: buyer,

    # Always matches account currencies
    sell_currency: sell_currency,
    buy_currency: buy_currency,

    sell_amount: sell_amount,
    buy_amount: buy_amount,
    exchange_rate: exchange_rate,
    wage: rand(0..50_000_000),
    kind: kind,
    pending: pending,
    pending_set_time: pending ? Faker::Time.between(
      from: 30.days.ago,
      to: Time.current
      ) : nil
    )


  Xtransfer
  .where(status: "finished")
  .order("RANDOM()")
  .limit(rand(0..3))
  .each do |transfer|

    ExchangeTransfer.create!(
      exchange: exchange,
      xtransfer: transfer
      )
  end
end

puts "Created #{Exchange.count} exchanges."
puts "Creating remittances..."

30.times do
  sender_account = accounts.sample

  receiver_account =
  accounts
  .reject { |account| account.id == sender_account.id }
  .sample

  currency = currencies.sample

  sent_amount = rand(100_000..5_000_000_000)

  Remittance.create!(
    sender_account: sender_account,
    receiver_account: receiver_account,
    currency: currency,
    sent_amount: sent_amount,
    received_amount: rand(
      (sent_amount * 0.8).to_i..
      (sent_amount * 1.2).to_i
      )
    )
end

puts "Created #{Remittance.count} remittances."


puts "Creating payments..."

30.times do
  sender_account = accounts.sample

  receiver_account =
    accounts
      .reject { |account| account.id == sender_account.id }
      .sample

  Xpayment.create!(
    sender_account: sender_account,
    receiver_account: receiver_account,
    currency: currencies.sample,
    sent_amount: rand(1_000_000..500_000_000),
    received_amount: rand(1_000_000..500_000_000),
    wage: rand(0..500_000_000)
  )
end

puts "Created #{Xpayment.count} payments."


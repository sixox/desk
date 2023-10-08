# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

ActiveRecord::Base.transaction do
	user_count = User.count
	VACATION_TYPE = ['Paid', 'Unpaid', 'Medical']


	700.times do
		  vacation_type = VACATION_TYPE.sample # Randomly select a vacation_type from the array

		  user_id = rand(1..user_count) 
		  start_date = Faker::Time.between(from: 1.year.ago, to: Time.now)
		  end_date = start_date + rand(1..10).days
		  Vacation.create(
		  	user_id: user_id,
		  	start_at: start_date,
		  	end_at: end_date,
		  	confirm: [true, false].sample,
		  	vacation_type: vacation_type,
		  	details: "some reason"
		  	)

		end
	end

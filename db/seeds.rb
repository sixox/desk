# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

ActiveRecord::Base.transaction do
	User.create(email: "mohsen@desk.com", first_name: "mohsen", last_name: "dehghani", username: "sixox1", profile_title: "special", about: "write description here ..", role: :admin, is_manager: true, password: "@desk@1234")
	User.create(email: "amin@desk.com", first_name: "amin", last_name: "mohammadi", username: "sixox2", profile_title: "sales", about: "write description here ..", role: :sales, password: "@desk@1234")
	User.create(email: "saffar@desk.com", first_name: "saffar", last_name: "mohammadi", username: "sixox3", profile_title: "hr", about: "write description here ..", role: :hr, password: "@desk@1234")
	User.create(email: "farzin@desk.com", first_name: "farzin", last_name: "serajinejad", username: "sixox4", profile_title: "special", about: "write description here ..", role: :accounting, is_manager: true, password: "@desk@1234")
	User.create(email: "farnaz@desk.com", first_name: "farnaz", last_name: "jalili", username: "sixox5", profile_title: "sales", about: "write description here ..", role: :sales, password: "@desk@1234")
	User.create(email: "yasamin@desk.com", first_name: "yasamin", last_name: "heidary", username: "sixox6", profile_title: "special", about: "write description here ..", role: :sales, is_manager: true, password: "@desk@1234")
	User.create(email: "soheil@desk.com", first_name: "soheil", last_name: "jamshidi", username: "sixox8", profile_title: "special", about: "write description here ..", role: :hr, password: "@desk@1234")
	User.create(email: "reza@desk.com", first_name: "reza", last_name: "abedi", username: "sixox9", profile_title: "special", about: "write description here ..", role: :hr, is_manager: true, password: "@desk@1234")
	User.create(email: "masoud@desk.com", first_name: "masoud", last_name: "khosravi", username: "sixox10", profile_title: "coo", about: "write description here ..", role: :procurement, is_manager: true, password: "@desk@1234")
	User.create(email: "samira@desk.com", first_name: "samira", last_name: "farahani", username: "sixox11", profile_title: "logestic", about: "write description here ..", role: :sales, password: "@desk@1234")
	User.create(email: "shohre@desk.com", first_name: "shohre", last_name: "hokamiyan", username: "sixox12", profile_title: "hr", about: "write description here ..", role: :hr, password: "@desk@1234")
	User.create(email: "mojtaba@desk.com", first_name: "mojtaba", last_name: "hokamiyan", username: "sixox13", profile_title: "hr", about: "write description here ..", role: :hr, password: "@desk@1234")
	User.create(email: "reza.d@desk.com", first_name: "reza", last_name: "doosti", username: "sixox14", profile_title: "hr", about: "write description here ..", role: :hr, password: "@desk@1234")
	User.create(email: "sepehr@desk.com", first_name: "sepehr", last_name: "mohammadi", username: "sixox15", profile_title: "hr", about: "write description here ..", role: :hr, password: "@desk@1234")
	User.create(email: "hamed@desk.com", first_name: "hamed", last_name: "iranshahy", username: "sixox16", profile_title: "procurement", about: "write description here ..", role: :procurement, password: "@desk@1234")	
	User.create(email: "mohadese@desk.com", first_name: "mohadese", last_name: "faris abadi", username: "sixox17", profile_title: "sales", about: "write description here ..", role: :sales, password: "@desk@1234")
	User.create(email: "homayon@desk.com", first_name: "homayon", last_name: "heidary", username: "sixox18", profile_title: "board", about: "write description here ..", role: :board, is_manager: true, password: "@desk@1234")
	User.create(email: "farzad@desk.com", first_name: "farzad", last_name: "yazdi", username: "sixox19", profile_title: "exchange", about: "write description here ..", role: :exchange, is_manager: true, password: "@desk@1234")
	User.create(email: "milad@desk.com", first_name: "milad", last_name: "yazdi", username: "sixox20", profile_title: "ceo", about: "write description here ..", role: :ceo, is_manager: true, password: "@desk@1234")
	User.create(email: "amir@desk.com", first_name: "amir", last_name: "yazdi", username: "sixox21", profile_title: "board", about: "write description here ..", role: :ceo, is_manager: true, password: "@desk@1234")
	User.create(email: "sarvenaz@desk.com", first_name: "sarvenaz", last_name: "ehteshaminia", username: "sixox22", profile_title: "hr", about: "write description here ..", role: :hr, password: "@desk@1234")
	User.create(email: "afsane@desk.com", first_name: "afsane", last_name: "sadeghi", username: "sixox23", profile_title: "exchange", about: "write description here ..", role: :exchange, password: "@desk@1234")
	User.create(email: "mostafa@desk.com", first_name: "mostafa", last_name: "baghban", username: "sixox24", profile_title: "exchange", about: "write description here ..", role: :exchange, password: "@desk@1234")
	User.create(email: "adnan@desk.com", first_name: "adnan", last_name: "mosavie", username: "sixox25", profile_title: "special", about: "write description here ..", role: :procurement, password: "@desk@1234")
	User.create(email: "emran@desk.com", first_name: "emran", last_name: "hosiengholi khan", username: "sixox26", profile_title: "procurement", about: "write description here ..", role: :procurement, password: "@desk@1234")
	User.create(email: "hadi@desk.com", first_name: "hadi", last_name: "azizpour", username: "sixox27", profile_title: "hr", about: "write description here ..", role: :hr, password: "@desk@1234")
	User.create(email: "amir.f@desk.com", first_name: "amir", last_name: "fakhim", username: "sixox28", profile_title: "special", about: "write description here ..", role: :marketing, is_manager: true, password: "@desk@1234")
	User.create(email: "behrad@desk.com", first_name: "behrad", last_name: "tarabi", username: "sixox29", profile_title: "accounting", about: "write description here ..", role: :accounting, password: "@desk@1234")















end

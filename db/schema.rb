# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_10_05_075202) do
  create_table "payment_orders", force: :cascade do |t|
    t.string "reference"
    t.integer "amount"
    t.string "from"
    t.string "to"
    t.string "receiver"
    t.string "receiver_account"
    t.text "details"
    t.float "exchange_rate"
    t.float "exchange_amount"
    t.boolean "have_factor"
    t.boolean "inserted"
    t.string "payment_type"
    t.boolean "department_confirm"
    t.boolean "accounting_confirm"
    t.boolean "ceo_confirm"
    t.string "status"
    t.string "currency"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_payment_orders_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "first_name"
    t.string "last_name"
    t.string "username"
    t.string "profile_title"
    t.text "about"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vacations", force: :cascade do |t|
    t.boolean "hourly"
    t.string "status"
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean "confirm"
    t.integer "user_id", null: false
    t.text "details"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vacation_type"
    t.index ["user_id"], name: "index_vacations_on_user_id"
  end

  add_foreign_key "payment_orders", "users"
  add_foreign_key "vacations", "users"
end

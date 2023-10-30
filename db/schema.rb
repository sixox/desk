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

ActiveRecord::Schema[7.0].define(version: 2023_10_30_061656) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ballance_projects", force: :cascade do |t|
    t.integer "quantity"
    t.integer "ballance_id", null: false
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ballance_id"], name: "index_ballance_projects_on_ballance_id"
    t.index ["project_id"], name: "index_ballance_projects_on_project_id"
  end

  create_table "ballances", force: :cascade do |t|
    t.string "number"
    t.string "status"
    t.string "name"
    t.string "product"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supplier_id", null: false
    t.index ["supplier_id"], name: "index_ballances_on_supplier_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.string "number"
    t.string "line"
    t.string "forwarder"
    t.string "pod"
    t.string "container_type"
    t.boolean "have_flexi"
    t.integer "quantity"
    t.date "validation_date"
    t.integer "free_time"
    t.string "status"
    t.integer "picked_up"
    t.string "payment_status"
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "filled"
    t.date "factory_order_date"
    t.date "pick_up_date"
    t.boolean "stuffing"
    t.boolean "custom_clearance"
    t.date "custom_submission_date"
    t.date "vessel_etd"
    t.index ["project_id"], name: "index_bookings_on_project_id"
  end

  create_table "cis", force: :cascade do |t|
    t.integer "pi_id"
    t.float "net_weight"
    t.float "gross_weight"
    t.float "total_price"
    t.float "advance_payment"
    t.float "balance_payment"
    t.string "bank_account"
    t.date "issue_date"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "number"
    t.integer "validity"
    t.index ["pi_id"], name: "index_cis_on_pi_id"
    t.index ["project_id"], name: "index_cis_on_project_id"
    t.index ["user_id"], name: "index_cis_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "nickname"
    t.string "company"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

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
    t.integer "project_id"
    t.integer "sci_id"
    t.integer "spi_id"
    t.integer "ballance_id"
    t.integer "booking_id"
    t.boolean "is_rahkarsazan"
    t.boolean "coo_confirm"
    t.boolean "delivery_confirm"
    t.index ["ballance_id"], name: "index_payment_orders_on_ballance_id"
    t.index ["booking_id"], name: "index_payment_orders_on_booking_id"
    t.index ["project_id"], name: "index_payment_orders_on_project_id"
    t.index ["sci_id"], name: "index_payment_orders_on_sci_id"
    t.index ["spi_id"], name: "index_payment_orders_on_spi_id"
    t.index ["user_id"], name: "index_payment_orders_on_user_id"
  end

  create_table "pis", force: :cascade do |t|
    t.string "number"
    t.string "product"
    t.integer "validity"
    t.float "quantity"
    t.float "unit_price"
    t.string "payment_term"
    t.string "bank_account"
    t.string "packing_type"
    t.integer "packing_count"
    t.float "shipment_rate"
    t.string "seller"
    t.integer "delivery_time"
    t.date "issue_date"
    t.string "pol"
    t.string "pod"
    t.integer "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "project_id"
    t.string "currency"
    t.float "total_price"
    t.index ["customer_id"], name: "index_pis_on_customer_id"
    t.index ["project_id"], name: "index_pis_on_project_id"
    t.index ["user_id"], name: "index_pis_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "number"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
  end

  create_table "scis", force: :cascade do |t|
    t.integer "spi_id", null: false
    t.float "net_weight"
    t.float "gross_weight"
    t.float "total_price"
    t.float "advance_payment"
    t.float "balance_payment"
    t.string "bank_account"
    t.date "issue_date"
    t.boolean "have_loading_report"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "ballance_id", null: false
    t.string "number"
    t.index ["ballance_id"], name: "index_scis_on_ballance_id"
    t.index ["spi_id"], name: "index_scis_on_spi_id"
    t.index ["user_id"], name: "index_scis_on_user_id"
  end

  create_table "spis", force: :cascade do |t|
    t.string "number"
    t.string "product"
    t.integer "validity"
    t.integer "user_id", null: false
    t.float "quantity"
    t.float "unit_price"
    t.string "payment_term"
    t.string "bank_account"
    t.string "packing_type"
    t.integer "packing_count"
    t.string "supplier"
    t.string "seller"
    t.date "issue_date"
    t.string "term"
    t.integer "ballance_id", null: false
    t.float "total_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ballance_id"], name: "index_spis_on_ballance_id"
    t.index ["user_id"], name: "index_spis_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_suppliers_on_user_id"
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
    t.string "role"
    t.boolean "is_manager"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
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
    t.string "vacation_type"
    t.index ["user_id"], name: "index_vacations_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ballance_projects", "ballances"
  add_foreign_key "ballance_projects", "projects"
  add_foreign_key "ballances", "suppliers"
  add_foreign_key "bookings", "projects"
  add_foreign_key "cis", "pis"
  add_foreign_key "cis", "projects"
  add_foreign_key "cis", "users"
  add_foreign_key "payment_orders", "ballances"
  add_foreign_key "payment_orders", "bookings"
  add_foreign_key "payment_orders", "projects"
  add_foreign_key "payment_orders", "scis"
  add_foreign_key "payment_orders", "spis"
  add_foreign_key "payment_orders", "users"
  add_foreign_key "pis", "customers"
  add_foreign_key "pis", "projects"
  add_foreign_key "pis", "users"
  add_foreign_key "scis", "ballances"
  add_foreign_key "scis", "spis"
  add_foreign_key "scis", "users"
  add_foreign_key "spis", "ballances"
  add_foreign_key "spis", "users"
  add_foreign_key "suppliers", "users"
  add_foreign_key "vacations", "users"
end

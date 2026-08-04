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

ActiveRecord::Schema[7.1].define(version: 2026_08_04_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "climbing_areas", force: :cascade do |t|
    t.string "name"
    t.string "rock_type"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "faqs", force: :cascade do |t|
    t.string "question", default: "", null: false
    t.text "answer", default: "", null: false
    t.bigint "watched_area_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["watched_area_id"], name: "index_faqs_on_watched_area_id"
  end

  create_table "local_climbing_orgs", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "slug", default: "", null: false
    t.index ["slug"], name: "index_local_climbing_orgs_on_slug", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.string "longitude"
    t.string "latitude"
    t.string "mt_z"
    t.bigint "climbing_area_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["climbing_area_id"], name: "index_locations_on_climbing_area_id"
  end

  create_table "rainy_day_areas", force: :cascade do |t|
    t.bigint "climbing_area_id"
    t.bigint "watched_area_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "driving_time"
    t.index ["climbing_area_id"], name: "index_rainy_day_areas_on_climbing_area_id"
    t.index ["watched_area_id"], name: "index_rainy_day_areas_on_watched_area_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.boolean "admin"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "approved", default: false, null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.boolean "super_admin", default: false, null: false
    t.text "manages", default: "--- []\n"
    t.index ["approved"], name: "index_users_on_approved"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "watched_areas", force: :cascade do |t|
    t.string "name"
    t.string "slug", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "local_climbing_org_id"
    t.string "park_type_word", default: "area", null: false
    t.text "info_bubble_excerpt", default: "", null: false
    t.text "landing_paragraph", default: "", null: false
    t.string "photo_credit_name", default: "", null: false
    t.string "photo_credit_link", default: "", null: false
    t.string "longitude", default: "0", null: false
    t.string "latitude", default: "0", null: false
    t.boolean "manual_warn", default: false, null: false
    t.string "station", default: ""
    t.string "webcam_stid"
    t.index ["local_climbing_org_id"], name: "index_watched_areas_on_local_climbing_org_id"
    t.index ["slug"], name: "index_watched_areas_on_slug", unique: true
  end

  add_foreign_key "locations", "climbing_areas"
  add_foreign_key "rainy_day_areas", "climbing_areas"
  add_foreign_key "rainy_day_areas", "watched_areas"
  add_foreign_key "watched_areas", "local_climbing_orgs"
end

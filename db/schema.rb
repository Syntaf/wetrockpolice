# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190429012026) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "climbing_areas", force: :cascade do |t|
    t.string "name"
    t.string "rock_type"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string "longitude"
    t.string "latitude"
    t.string "mt_z"
    t.bigint "climbing_area_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["climbing_area_id"], name: "index_locations_on_climbing_area_id"
  end

  create_table "rainy_day_areas", force: :cascade do |t|
    t.bigint "climbing_area_id"
    t.bigint "watched_area_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["climbing_area_id"], name: "index_rainy_day_areas_on_climbing_area_id"
    t.index ["watched_area_id"], name: "index_rainy_day_areas_on_watched_area_id"
  end

  create_table "watched_areas", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "locations", "climbing_areas"
  add_foreign_key "rainy_day_areas", "climbing_areas"
  add_foreign_key "rainy_day_areas", "watched_areas"
end

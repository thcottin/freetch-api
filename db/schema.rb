# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140529022451) do

  create_table "feedback_associations", force: true do |t|
    t.integer "sweetch_id"
    t.integer "feedback_id"
    t.integer "user_id"
  end

  create_table "feedbacks", force: true do |t|
    t.string "message"
    t.string "driver"
  end

  create_table "locations", force: true do |t|
    t.float    "lat"
    t.float    "lng"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "message_views", force: true do |t|
    t.string   "ref"
    t.string   "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "properties", force: true do |t|
    t.string "key"
    t.string "value"
  end

  create_table "sweetches", force: true do |t|
    t.string   "leaver_id"
    t.string   "parker_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.string   "scheduled_push_id"
    t.string   "charge_token"
    t.float    "parker_lat"
    t.float    "parker_lng"
    t.float    "leaver_lat"
    t.float    "leaver_lng"
  end

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                    default: false
    t.integer  "facebook_id",    limit: 8
    t.string   "device_token"
    t.integer  "count_sweetch"
    t.string   "customer_token"
    t.integer  "credits",                  default: 0
    t.string   "address"
    t.string   "zipcode"
    t.string   "phone"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["facebook_id"], name: "index_users_on_facebook_id"

end

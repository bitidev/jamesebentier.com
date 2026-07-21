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

ActiveRecord::Schema[8.1].define(version: 2026_07_21_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "page_views", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_version", default: 1, null: false
    t.string "path", limit: 2048, null: false
    t.datetime "recorded_at", null: false
    t.string "referrer", limit: 500
    t.datetime "updated_at", null: false
    t.string "utm_campaign", limit: 255
    t.string "utm_medium", limit: 255
    t.string "utm_source", limit: 255
    t.string "visitor_type", limit: 10, default: "human", null: false
    t.index ["path", "recorded_at"], name: "index_page_views_on_path_and_recorded_at"
    t.index ["recorded_at"], name: "index_page_views_on_recorded_at"
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "description", limit: 1024, null: false
    t.string "excerpt", limit: 280, default: "", null: false
    t.boolean "featured", default: false, null: false
    t.string "file_path", limit: 1024, null: false
    t.string "image", limit: 1024, default: "", null: false
    t.string "keywords", limit: 1024, null: false
    t.string "kind", limit: 20, default: "deep_dive", null: false
    t.integer "lock_version", default: 1, null: false
    t.string "medium_url", limit: 1024
    t.datetime "published_at", precision: nil, null: false
    t.string "slug", limit: 255, null: false
    t.json "tags", default: [], null: false
    t.string "title", limit: 1024, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description", null: false
    t.boolean "featured", default: false, null: false
    t.string "image", limit: 1024, null: false
    t.integer "lock_version", default: 1, null: false
    t.string "read_url", limit: 1024
    t.string "slug", limit: 255, null: false
    t.string "source_url", limit: 1024
    t.string "status", limit: 255, default: "Beta", null: false
    t.string "title", limit: 1024, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "url", limit: 1024, null: false
    t.index ["slug"], name: "index_projects_on_slug", unique: true
  end

  create_table "subscribers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at", precision: nil
    t.datetime "consent_at", precision: nil
    t.string "consent_source", limit: 50
    t.datetime "created_at", precision: nil, null: false
    t.string "email", limit: 255, null: false
    t.string "ip_hash", limit: 64
    t.integer "lock_version", default: 1, null: false
    t.datetime "unsubscribed_at", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.index ["confirmation_token"], name: "index_subscribers_on_confirmation_token", unique: true
    t.index ["email"], name: "index_subscribers_on_email", unique: true
  end
end

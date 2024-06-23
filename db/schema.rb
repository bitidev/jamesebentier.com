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

ActiveRecord::Schema[7.1].define(version: 2024_06_23_144007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "slug", limit: 255, null: false
    t.string "title", limit: 1024, null: false
    t.string "description", limit: 1024, null: false
    t.string "keywords", limit: 1024, null: false
    t.string "image", limit: 1024, default: "", null: false
    t.string "file_path", limit: 1024, null: false
    t.datetime "published_at", precision: nil, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "lock_version", default: 1, null: false
    t.json "tags", default: [], null: false
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "slug", limit: 255, null: false
    t.string "title", limit: 1024, null: false
    t.string "status", limit: 255, default: "Beta", null: false
    t.string "url", limit: 1024, null: false
    t.string "image", limit: 1024, null: false
    t.text "description", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "lock_version", default: 1, null: false
    t.index ["slug"], name: "index_projects_on_slug", unique: true
  end

end

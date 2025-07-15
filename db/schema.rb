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

ActiveRecord::Schema[8.0].define(version: 2025_07_15_092704) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "creators", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "bio"
    t.integer "status", default: 0, null: false
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_creators_on_status"
    t.index ["user_id"], name: "index_creators_on_user_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "venue_name", null: false
    t.string "venue_address", null: false
    t.date "event_date", null: false
    t.time "start_time", null: false
    t.integer "max_capacity", null: false
    t.integer "price_cents", null: false
    t.integer "status", default: 0, null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_date"], name: "index_events_on_event_date"
    t.index ["latitude", "longitude"], name: "index_events_on_latitude_and_longitude"
    t.index ["movie_id"], name: "index_events_on_movie_id"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "movies", force: :cascade do |t|
    t.bigint "creator_id", null: false
    t.string "title", null: false
    t.text "synopsis", null: false
    t.string "director", null: false
    t.integer "duration", null: false
    t.string "genre", null: false
    t.string "language", default: "fr"
    t.integer "year", null: false
    t.string "trailer_url"
    t.string "poster_url"
    t.integer "validation_status", default: 0, null: false
    t.bigint "validated_by_id"
    t.datetime "validated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_movies_on_creator_id"
    t.index ["genre"], name: "index_movies_on_genre"
    t.index ["validated_by_id"], name: "index_movies_on_validated_by_id"
    t.index ["validation_status"], name: "index_movies_on_validation_status"
  end

  create_table "participations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.string "stripe_payment_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_participations_on_event_id"
    t.index ["status"], name: "index_participations_on_status"
    t.index ["user_id", "event_id"], name: "index_participations_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_participations_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "movie_id", null: false
    t.bigint "event_id", null: false
    t.integer "rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_reviews_on_event_id"
    t.index ["movie_id"], name: "index_reviews_on_movie_id"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["user_id", "movie_id", "event_id"], name: "index_reviews_on_user_movie_event", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "role", default: 0, null: false
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "creators", "users"
  add_foreign_key "events", "movies"
  add_foreign_key "movies", "creators"
  add_foreign_key "movies", "users", column: "validated_by_id"
  add_foreign_key "participations", "events"
  add_foreign_key "participations", "users"
  add_foreign_key "reviews", "events"
  add_foreign_key "reviews", "movies"
  add_foreign_key "reviews", "users"
end

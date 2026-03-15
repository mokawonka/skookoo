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

ActiveRecord::Schema[7.2].define(version: 2026_03_14_163653) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "action_text_rich_texts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "api_key"
    t.string "claim_token"
    t.string "verification_code"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "userid"
    t.index ["api_key"], name: "index_agents_on_api_key", unique: true
    t.index ["claim_token"], name: "index_agents_on_claim_token", unique: true
    t.index ["userid"], name: "index_agents_on_userid"
  end

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "epubid"
    t.uuid "userid"
    t.string "title"
    t.string "authors"
    t.boolean "ispublic"
    t.decimal "progress"
    t.integer "opened"
    t.string "locations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_accessed_at"
    t.integer "font_size", default: 18
    t.float "line_height", default: 1.6
    t.string "bg_color", default: "#ffffff"
    t.string "text_color", default: "#111111"
    t.string "font_family", default: "Crimson Pro"
    t.boolean "user_created", default: false, null: false
    t.string "nature", default: "book"
    t.index ["last_accessed_at"], name: "index_documents_on_last_accessed_at"
  end

  create_table "epubs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.string "authors"
    t.string "lang"
    t.string "sha3"
    t.boolean "public_domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "expressions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "userid"
    t.uuid "docid"
    t.string "cfi"
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "definition", limit: 1000
    t.string "origin"
  end

  create_table "feature_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.uuid "user_id", null: false
    t.integer "status"
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_feature_requests_on_user_id"
  end

  create_table "highlights", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "userid"
    t.uuid "docid"
    t.string "quote"
    t.string "fromauthors"
    t.string "fromtitle"
    t.string "cfi"
    t.integer "score"
    t.boolean "liked"
    t.string "comment"
    t.string "gifid"
    t.string "emojiid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quote"], name: "index_highlights_on_quote_trigram", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "merch_orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "highlight_id", null: false
    t.string "product_type"
    t.text "design_text"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color"
    t.integer "quantity"
    t.index ["highlight_id"], name: "index_merch_orders_on_highlight_id"
    t.index ["user_id"], name: "index_merch_orders_on_user_id"
  end

  create_table "noticed_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type"
    t.string "record_type"
    t.uuid "record_id"
    t.jsonb "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notifications_count"
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "event_id", null: false
    t.string "recipient_type", null: false
    t.uuid "recipient_id", null: false
    t.datetime "read_at", precision: nil
    t.datetime "seen_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "replies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "userid"
    t.uuid "highlightid"
    t.uuid "recipientid"
    t.integer "score"
    t.boolean "deleted"
    t.boolean "edited"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "plan"
    t.integer "status"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.datetime "current_period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.string "password_digest"
    t.string "password_confirmation"
    t.string "name"
    t.integer "mana"
    t.text "votes"
    t.boolean "darkmode"
    t.string "font"
    t.boolean "allownotifications"
    t.uuid "hooked"
    t.string "bio"
    t.string "location"
    t.text "following"
    t.text "followers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "emailnotifications"
    t.boolean "private_profile", default: false, null: false
    t.text "pending_follow_requests", default: "[]"
    t.index "lower((name)::text)", name: "index_users_on_lower_name"
    t.index "lower((username)::text)", name: "index_users_on_lower_username"
    t.index ["name"], name: "index_users_on_name_trigram", opclass: :gist_trgm_ops, using: :gist
    t.index ["username"], name: "index_users_on_username_trigram", opclass: :gist_trgm_ops, using: :gist
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "feature_requests", "users"
  add_foreign_key "merch_orders", "highlights"
  add_foreign_key "merch_orders", "users"
  add_foreign_key "subscriptions", "users"
end

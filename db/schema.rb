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

ActiveRecord::Schema[8.1].define(version: 2026_05_20_124843) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "actor_label"
    t.datetime "created_at", null: false
    t.bigint "defect_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_activity_events_on_actor_id"
    t.index ["defect_id", "created_at"], name: "index_activity_events_on_defect_id_and_created_at"
    t.index ["defect_id"], name: "index_activity_events_on_defect_id"
    t.index ["organization_id", "created_at"], name: "index_activity_events_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_activity_events_on_organization_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "defect_id", null: false
    t.datetime "ends_at"
    t.text "notes"
    t.bigint "organization_id", null: false
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["defect_id"], name: "index_appointments_on_defect_id"
    t.index ["organization_id", "scheduled_at"], name: "index_appointments_on_organization_id_and_scheduled_at"
    t.index ["organization_id"], name: "index_appointments_on_organization_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "defect_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["defect_id", "created_at"], name: "index_comments_on_defect_id_and_created_at"
    t.index ["defect_id"], name: "index_comments_on_defect_id"
    t.index ["organization_id"], name: "index_comments_on_organization_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "contractor_companies", force: :cascade do |t|
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "organization_id", null: false
    t.string "phone"
    t.bigint "trade_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_contractor_companies_on_organization_id"
    t.index ["trade_id"], name: "index_contractor_companies_on_trade_id"
  end

  create_table "contractor_memberships", force: :cascade do |t|
    t.bigint "contractor_company_id", null: false
    t.datetime "created_at", null: false
    t.integer "role"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["contractor_company_id"], name: "index_contractor_memberships_on_contractor_company_id"
    t.index ["user_id"], name: "index_contractor_memberships_on_user_id"
  end

  create_table "defects", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "assigned_at"
    t.datetime "closed_at"
    t.datetime "completed_at"
    t.bigint "contractor_company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "organization_id", null: false
    t.bigint "plot_id"
    t.integer "priority", default: 1, null: false
    t.string "reference"
    t.bigint "reporter_id"
    t.bigint "site_id", null: false
    t.date "sla_target_date"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.bigint "trade_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contractor_company_id", "status"], name: "index_defects_on_contractor_company_id_and_status"
    t.index ["contractor_company_id"], name: "index_defects_on_contractor_company_id"
    t.index ["organization_id", "id"], name: "idx_defects_open", where: "(status < 7)"
    t.index ["organization_id", "sla_target_date"], name: "idx_defects_open_by_sla", where: "(status < 7)"
    t.index ["organization_id", "sla_target_date"], name: "index_defects_on_organization_id_and_sla_target_date"
    t.index ["organization_id", "status"], name: "index_defects_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_defects_on_organization_id"
    t.index ["plot_id"], name: "index_defects_on_plot_id"
    t.index ["reporter_id"], name: "index_defects_on_reporter_id"
    t.index ["site_id", "status"], name: "index_defects_on_site_id_and_status"
    t.index ["site_id"], name: "index_defects_on_site_id"
    t.index ["trade_id"], name: "index_defects_on_trade_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.bigint "defect_id"
    t.string "event_type", null: false
    t.bigint "organization_id", null: false
    t.text "preview"
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["defect_id"], name: "index_notifications_on_defect_id"
    t.index ["organization_id"], name: "index_notifications_on_organization_id"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "plots", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "plot_number"
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_plots_on_organization_id"
    t.index ["site_id"], name: "index_plots_on_site_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sign_offs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "defect_id", null: false
    t.string "ip_address"
    t.bigint "organization_id", null: false
    t.text "signature_data"
    t.datetime "signed_at", null: false
    t.string "signer_email"
    t.string "signer_name", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["defect_id"], name: "index_sign_offs_on_defect_id", unique: true
    t.index ["organization_id"], name: "index_sign_offs_on_organization_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "organization_id", null: false
    t.string "reference"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_sites_on_organization_id"
  end

  create_table "sla_policies", force: :cascade do |t|
    t.integer "amber_threshold_hours", default: 48, null: false
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.integer "priority", default: 1, null: false
    t.bigint "site_id"
    t.integer "target_days", null: false
    t.bigint "trade_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "priority"], name: "index_sla_policies_on_organization_id_and_priority"
    t.index ["organization_id"], name: "index_sla_policies_on_organization_id"
    t.index ["site_id"], name: "index_sla_policies_on_site_id"
    t.index ["trade_id"], name: "index_sla_policies_on_trade_id"
  end

  create_table "trades", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "default_sla_days"
    t.string "name"
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_trades_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.bigint "organization_id"
    t.string "password_digest", null: false
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_events", "defects"
  add_foreign_key "activity_events", "organizations"
  add_foreign_key "activity_events", "users", column: "actor_id"
  add_foreign_key "appointments", "defects"
  add_foreign_key "appointments", "organizations"
  add_foreign_key "comments", "defects"
  add_foreign_key "comments", "organizations"
  add_foreign_key "comments", "users"
  add_foreign_key "contractor_companies", "organizations"
  add_foreign_key "contractor_companies", "trades"
  add_foreign_key "contractor_memberships", "contractor_companies"
  add_foreign_key "contractor_memberships", "users"
  add_foreign_key "defects", "contractor_companies"
  add_foreign_key "defects", "organizations"
  add_foreign_key "defects", "plots"
  add_foreign_key "defects", "sites"
  add_foreign_key "defects", "trades"
  add_foreign_key "defects", "users", column: "reporter_id"
  add_foreign_key "notifications", "defects"
  add_foreign_key "notifications", "organizations"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "plots", "organizations"
  add_foreign_key "plots", "sites"
  add_foreign_key "sessions", "users"
  add_foreign_key "sign_offs", "defects"
  add_foreign_key "sign_offs", "organizations"
  add_foreign_key "sites", "organizations"
  add_foreign_key "sla_policies", "organizations"
  add_foreign_key "sla_policies", "sites"
  add_foreign_key "sla_policies", "trades"
  add_foreign_key "trades", "organizations"
  add_foreign_key "users", "organizations"
end

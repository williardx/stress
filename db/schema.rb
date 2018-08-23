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

ActiveRecord::Schema.define(version: 2018_08_23_210320) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "fulfillments", force: :cascade do |t|
    t.string "courier"
    t.string "tracking_id"
    t.date "estimated_delivery"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "line_item_fulfillments", force: :cascade do |t|
    t.bigint "line_item_id"
    t.bigint "fulfillment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fulfillment_id"], name: "index_line_item_fulfillments_on_fulfillment_id"
    t.index ["line_item_id"], name: "index_line_item_fulfillments_on_line_item_id"
  end

  create_table "line_items", force: :cascade do |t|
    t.bigint "order_id"
    t.string "artwork_id"
    t.string "edition_set_id"
    t.integer "price_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity", default: 1, null: false
    t.index ["order_id"], name: "index_line_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "code"
    t.integer "shipping_total_cents"
    t.integer "tax_total_cents"
    t.integer "transaction_fee_cents"
    t.integer "commission_fee_cents"
    t.string "currency_code", limit: 3
    t.string "user_id"
    t.string "partner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", null: false
    t.string "credit_card_id"
    t.datetime "state_updated_at"
    t.datetime "state_expires_at"
    t.string "shipping_address_line1"
    t.string "shipping_address_line2"
    t.string "shipping_city"
    t.string "shipping_country"
    t.string "shipping_postal_code"
    t.string "fulfillment_type"
    t.string "shipping_region"
    t.string "external_charge_id"
    t.string "shipping_name"
    t.datetime "abandoned_at"
    t.datetime "submitted_at"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.datetime "fulfilled_at"
    t.index ["code"], name: "index_orders_on_code"
    t.index ["partner_id"], name: "index_orders_on_partner_id"
    t.index ["state"], name: "index_orders_on_state"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "order_id"
    t.string "external_id"
    t.string "source_id"
    t.string "destination_id"
    t.integer "amount_cents"
    t.string "failure_code"
    t.string "failure_message"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_type"
    t.index ["order_id"], name: "index_transactions_on_order_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "line_item_fulfillments", "fulfillments"
  add_foreign_key "line_item_fulfillments", "line_items"
  add_foreign_key "line_items", "orders"
  add_foreign_key "transactions", "orders"
end

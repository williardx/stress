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

ActiveRecord::Schema.define(version: 2018_06_26_201815) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "line_items", force: :cascade do |t|
    t.bigint "order_id"
    t.string "artwork_id"
    t.string "edition_set_id"
    t.integer "price_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "artwork_snapshot"
    t.integer "quantity", default: 1, null: false
    t.index ["order_id"], name: "index_line_items_on_order_id"
  end

  create_table "order_histories", force: :cascade do |t|
    t.bigint "order_id"
    t.string "modifier_id", null: false
    t.jsonb "changed_fields", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_histories_on_order_id"
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
    t.index ["code"], name: "index_orders_on_code"
    t.index ["partner_id"], name: "index_orders_on_partner_id"
    t.index ["state"], name: "index_orders_on_state"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  add_foreign_key "line_items", "orders"
  add_foreign_key "order_histories", "orders"
end

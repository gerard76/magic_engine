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

ActiveRecord::Schema.define(version: 20200309064958) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "abilities", force: :cascade do |t|
    t.integer "card_id"
    t.json    "cost"
    t.json    "effect"
    t.string  "activation"
    t.json    "duration"
    t.index ["card_id"], name: "index_abilities_on_card_id", using: :btree
  end

  create_table "cards", force: :cascade do |t|
    t.string  "name"
    t.integer "multiverse_id"
    t.string  "layout"
    t.string  "names",                       array: true
    t.string  "mana_cost"
    t.integer "cmc"
    t.string  "colors",                      array: true
    t.string  "color_identity",              array: true
    t.string  "card_type"
    t.text    "types",          default: [], array: true
    t.text    "supertypes",     default: [], array: true
    t.text    "subtypes",       default: [], array: true
    t.string  "rarity"
    t.string  "text"
    t.string  "flavor"
    t.string  "artist"
    t.string  "number"
    t.string  "power"
    t.string  "toughness"
    t.string  "loyalty"
    t.string  "variations"
    t.string  "watermark"
    t.string  "border"
    t.string  "timeshifted"
    t.string  "hand"
    t.string  "life"
    t.string  "reserved"
    t.string  "release_date"
    t.string  "starter"
    t.string  "rulings"
    t.string  "foreign_names"
    t.string  "printings"
    t.string  "original_text"
    t.string  "original_type"
    t.string  "legalities"
    t.string  "source"
    t.string  "image_url"
    t.string  "set"
    t.string  "set_name"
  end

  create_table "deck_cards", force: :cascade do |t|
    t.integer "deck_id"
    t.integer "card_id"
    t.index ["deck_id", "card_id"], name: "index_deck_cards_on_deck_id_and_card_id", using: :btree
  end

  create_table "decks", force: :cascade do |t|
    t.string "name"
  end

  create_table "matches", force: :cascade do |t|
    t.integer "deck_us"
    t.integer "desc_them"
    t.string  "draw_us"
    t.string  "draw_them"
    t.string  "actions"
  end

  create_table "triggers", force: :cascade do |t|
    t.integer "card_id"
    t.string  "trigger"
    t.string  "ability"
    t.index ["card_id"], name: "index_triggers_on_card_id", using: :btree
  end

end

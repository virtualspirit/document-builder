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

ActiveRecord::Schema.define(version: 2021_04_23_132751) do

  create_table "document_fields", force: :cascade do |t|
    t.string "name", null: false
    t.integer "accessibility", null: false
    t.text "options"
    t.text "validations"
    t.integer "position"
    t.string "type"
    t.integer "form_id"
    t.integer "section_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["form_id"], name: "index_document_fields_on_form_id"
    t.index ["section_id"], name: "index_document_fields_on_section_id"
  end

  create_table "document_forms", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.text "description"
    t.string "type"
    t.string "code"
    t.string "documentable_type"
    t.integer "documentable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["documentable_type", "documentable_id"], name: "index_document_forms_on_documentable"
  end

  create_table "document_sections", force: :cascade do |t|
    t.string "title", default: ""
    t.boolean "headless", default: false, null: false
    t.integer "form_id"
    t.integer "position"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["form_id"], name: "index_document_sections_on_form_id"
  end

end

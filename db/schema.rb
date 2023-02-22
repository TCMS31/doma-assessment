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

ActiveRecord::Schema[7.0].define(version: 2026_09_25_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.string "context", null: false
    t.string "next_question_external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "answer_type", null: false
    t.index ["next_question_external_id"], name: "index_answers_on_next_question_external_id"
    t.index ["question_id", "answer_type"], name: "index_answers_on_question_id_and_answer_type", unique: true
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "conclusions", force: :cascade do |t|
    t.string "name", null: false
    t.string "context", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_conclusions_on_name", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.string "statement", null: false
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_questions_on_external_id", unique: true
  end

  add_foreign_key "answers", "questions"
end

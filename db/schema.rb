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

ActiveRecord::Schema[8.1].define(version: 2025_12_28_175758) do
  create_table "folders", force: :cascade do |t|
    t.string "canonical_path", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_path"], name: "index_folders_on_canonical_path", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.integer "cache_creation_tokens", default: 0
    t.integer "cache_read_tokens", default: 0
    t.json "content", default: []
    t.datetime "created_at", null: false
    t.boolean "has_thinking", default: false
    t.integer "input_tokens", default: 0
    t.boolean "is_sidechain", default: false
    t.string "message_type", null: false
    t.string "model"
    t.integer "output_tokens", default: 0
    t.integer "parent_message_id"
    t.string "parent_uuid"
    t.integer "project_session_id", null: false
    t.string "role"
    t.json "thinking_metadata", default: {}
    t.datetime "timestamp", null: false
    t.json "todos", default: []
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["message_type"], name: "index_messages_on_message_type"
    t.index ["parent_message_id"], name: "index_messages_on_parent_message_id"
    t.index ["parent_uuid"], name: "index_messages_on_parent_uuid"
    t.index ["project_session_id", "timestamp"], name: "index_messages_on_project_session_id_and_timestamp"
    t.index ["project_session_id"], name: "index_messages_on_project_session_id"
    t.index ["uuid"], name: "index_messages_on_uuid", unique: true
  end

  create_table "project_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "sourceable_id", null: false
    t.string "sourceable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["sourceable_type", "sourceable_id"], name: "index_project_groups_on_sourceable_type_and_sourceable_id", unique: true
  end

  create_table "project_sessions", force: :cascade do |t|
    t.string "agent_id"
    t.string "claude_version"
    t.datetime "created_at", null: false
    t.string "cwd"
    t.datetime "ended_at"
    t.string "git_branch"
    t.boolean "is_sidechain", default: false
    t.integer "messages_count", default: 0
    t.integer "parent_project_session_id"
    t.integer "project_id", null: false
    t.string "session_id", null: false
    t.datetime "started_at"
    t.string "summary"
    t.integer "total_cache_creation_tokens", default: 0
    t.integer "total_cache_read_tokens", default: 0
    t.integer "total_input_tokens", default: 0
    t.integer "total_output_tokens", default: 0
    t.datetime "updated_at", null: false
    t.index ["parent_project_session_id"], name: "index_project_sessions_on_parent_project_session_id"
    t.index ["project_id", "session_id"], name: "index_project_sessions_on_project_id_and_session_id", unique: true
    t.index ["project_id"], name: "index_project_sessions_on_project_id"
    t.index ["session_id"], name: "index_project_sessions_on_session_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encoded_path", null: false
    t.decimal "last_cost", precision: 10, scale: 2
    t.json "last_model_usage", default: {}
    t.string "last_session_id"
    t.string "name"
    t.string "path", null: false
    t.integer "project_group_id"
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_projects_on_path", unique: true
    t.index ["project_group_id"], name: "index_projects_on_project_group_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "git_common_dir", null: false
    t.string "normalized_url"
    t.string "provider"
    t.string "remote_url"
    t.datetime "updated_at", null: false
    t.index ["git_common_dir"], name: "index_repositories_on_git_common_dir", unique: true
    t.index ["normalized_url"], name: "index_repositories_on_normalized_url"
  end

  create_table "session_plans", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "file_created_at"
    t.integer "project_session_id"
    t.string "slug", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["project_session_id"], name: "index_session_plans_on_project_session_id"
    t.index ["slug"], name: "index_session_plans_on_slug", unique: true
  end

  create_table "tool_uses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "input", default: {}
    t.integer "message_id", null: false
    t.json "result"
    t.boolean "success"
    t.string "tool_name", null: false
    t.string "tool_use_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_uses_on_message_id"
    t.index ["tool_name"], name: "index_tool_uses_on_tool_name"
    t.index ["tool_use_id"], name: "index_tool_uses_on_tool_use_id", unique: true
  end

  add_foreign_key "messages", "messages", column: "parent_message_id"
  add_foreign_key "messages", "project_sessions"
  add_foreign_key "project_sessions", "project_sessions", column: "parent_project_session_id"
  add_foreign_key "project_sessions", "projects"
  add_foreign_key "projects", "project_groups"
  add_foreign_key "session_plans", "project_sessions"
  add_foreign_key "tool_uses", "messages"
end

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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110316211438) do

  create_table "accounts", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",     :default => true, :null => false
    t.string   "time_zone"
  end

  add_index "accounts", ["active"], :name => "index_accounts_on_active"

  create_table "checklists", :force => true do |t|
    t.string   "name"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",     :default => true, :null => false
  end

  add_index "checklists", ["account_id"], :name => "index_checklists_on_account_id"
  add_index "checklists", ["active"], :name => "index_checklists_on_active"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "entries", :force => true do |t|
    t.integer  "checklist_id", :limit => 8
    t.string   "notes"
    t.integer  "user_id",      :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id",   :limit => 8
  end

  add_index "entries", ["account_id"], :name => "index_entries_on_account_id"
  add_index "entries", ["checklist_id"], :name => "index_entries_on_checklist_id"
  add_index "entries", ["created_at"], :name => "index_entries_on_created_at"
  add_index "entries", ["user_id"], :name => "index_entries_on_user_id"

  create_table "items", :force => true do |t|
    t.string   "content"
    t.integer  "checklist_id", :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["checklist_id"], :name => "index_items_on_checklist_id"

  create_table "users", :force => true do |t|
    t.string   "email",                              :default => "",     :null => false
    t.string   "encrypted_password",                 :default => ""
    t.string   "password_salt",                      :default => ""
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "invitation_token",     :limit => 60
    t.datetime "invitation_sent_at"
    t.string   "name"
    t.string   "role",                               :default => "user"
    t.integer  "account_id",           :limit => 8
    t.boolean  "active",                             :default => true,   :null => false
  end

  add_index "users", ["account_id"], :name => "index_users_on_account_id"
  add_index "users", ["active"], :name => "index_users_on_active"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end

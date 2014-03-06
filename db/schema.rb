# encoding: UTF-8
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

ActiveRecord::Schema.define(:version => 20131107191150) do

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "photo_id"
    t.text     "body"
    t.datetime "created_on"
  end

  add_index "comments", ["photo_id"], :name => "index_comments_on_photo_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "contact_details", :force => true do |t|
    t.integer  "contact_record_id"
    t.string   "field_name",        :limit => 50
    t.string   "field_value",       :limit => 150
    t.string   "kind",              :limit => 50
    t.integer  "country_code"
    t.string   "value",             :limit => 50
    t.string   "status",            :limit => 30
    t.datetime "created_on",                       :null => false
    t.datetime "updated_on",                       :null => false
  end

  add_index "contact_details", ["contact_record_id"], :name => "index_contact_details_on_contact_record_id"
  add_index "contact_details", ["kind"], :name => "index_contact_details_on_kind"
  add_index "contact_details", ["status"], :name => "index_contact_details_on_status"
  add_index "contact_details", ["value"], :name => "index_contact_details_on_value"

  create_table "contact_records", :force => true do |t|
    t.integer "user_id"
    t.integer "source_id"
    t.string  "first_name", :limit => 50
    t.string  "last_name",  :limit => 50
  end

  add_index "contact_records", ["first_name"], :name => "index_contact_records_on_first_name"
  add_index "contact_records", ["last_name"], :name => "index_contact_records_on_last_name"
  add_index "contact_records", ["user_id"], :name => "index_contact_records_on_user_id"

  create_table "devices", :force => true do |t|
    t.integer  "user_id"
    t.string   "platform"
    t.string   "version"
    t.datetime "created_on", :null => false
    t.datetime "updated_on", :null => false
  end

  add_index "devices", ["user_id"], :name => "index_devices_on_user_id"

  create_table "invites", :force => true do |t|
    t.integer  "occasion_id"
    t.integer  "inviter_id"
    t.integer  "invitee_id"
    t.datetime "created_on",  :null => false
    t.datetime "updated_on",  :null => false
  end

  add_index "invites", ["invitee_id"], :name => "index_invites_on_invitee_id"
  add_index "invites", ["inviter_id"], :name => "index_invites_on_inviter_id"
  add_index "invites", ["occasion_id"], :name => "index_invites_on_occasion_id"

  create_table "likes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "photo_id"
    t.datetime "created_on"
  end

  add_index "likes", ["photo_id"], :name => "index_likes_on_photo_id"
  add_index "likes", ["user_id"], :name => "index_likes_on_user_id"

  create_table "notifications", :force => true do |t|
    t.integer  "recipient_id"
    t.integer  "occasion_id"
    t.integer  "trigger_id"
    t.string   "trigger_type"
    t.integer  "contact_detail_id"
    t.string   "contact_value",     :limit => 50
    t.string   "kind"
    t.string   "template_id"
    t.string   "status",            :limit => 20
    t.string   "ext_id",            :limit => 50
    t.string   "hash_code",         :limit => 15
    t.datetime "created_on",                      :null => false
    t.datetime "updated_on",                      :null => false
  end

  add_index "notifications", ["hash_code"], :name => "index_notifications_on_hash_code"
  add_index "notifications", ["kind"], :name => "index_notifications_on_kind"
  add_index "notifications", ["occasion_id"], :name => "index_notifications_on_occasion_id"
  add_index "notifications", ["recipient_id"], :name => "index_notifications_on_recipient_id"
  add_index "notifications", ["status"], :name => "index_notifications_on_status"
  add_index "notifications", ["trigger_type", "trigger_id"], :name => "index_notifications_on_trigger_type_and_trigger_id"

  create_table "occasion_pop_estimates", :force => true do |t|
    t.integer  "occasion_id"
    t.integer  "user_id"
    t.integer  "value"
    t.datetime "created_on",  :null => false
    t.datetime "updated_on",  :null => false
  end

  add_index "occasion_pop_estimates", ["occasion_id"], :name => "index_occasion_pop_estimates_on_occasion_id"
  add_index "occasion_pop_estimates", ["user_id"], :name => "index_occasion_pop_estimates_on_user_id"

  create_table "occasion_viewings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "occasion_id"
    t.datetime "time"
  end

  add_index "occasion_viewings", ["user_id"], :name => "index_occasion_viewings_on_user_id"

  create_table "occasions", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.float    "longitude"
    t.float    "latitude"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string   "city",               :limit => 50
    t.datetime "created_on",                       :null => false
    t.datetime "updated_on",                       :null => false
    t.datetime "content_updated_on"
  end

  add_index "occasions", ["user_id"], :name => "index_occasions_on_user_id"

  create_table "participations", :force => true do |t|
    t.integer  "occasion_id"
    t.integer  "user_id"
    t.integer  "indication_id"
    t.string   "indication_type"
    t.string   "kind"
    t.datetime "created_on",      :null => false
    t.datetime "updated_on",      :null => false
  end

  add_index "participations", ["indication_type", "indication_id"], :name => "index_participations_on_indication_type_and_indication_id"
  add_index "participations", ["occasion_id"], :name => "index_participations_on_occasion_id"
  add_index "participations", ["user_id"], :name => "index_participations_on_user_id"

  create_table "photo_taggings", :force => true do |t|
    t.integer  "photo_id"
    t.integer  "tagger_id"
    t.integer  "taggee_id"
    t.integer  "tlx"
    t.integer  "tly"
    t.integer  "brx"
    t.integer  "bry"
    t.datetime "created_on", :null => false
    t.datetime "updated_on", :null => false
  end

  add_index "photo_taggings", ["photo_id"], :name => "index_photo_taggings_on_photo_id"
  add_index "photo_taggings", ["taggee_id"], :name => "index_photo_taggings_on_taggee_id"
  add_index "photo_taggings", ["tagger_id"], :name => "index_photo_taggings_on_tagger_id"

  create_table "photos", :force => true do |t|
    t.integer  "user_id"
    t.float    "longitude"
    t.float    "latitude"
    t.integer  "occasion_id"
    t.string   "pic_file_name"
    t.string   "pic_content_type"
    t.integer  "pic_file_size"
    t.datetime "pic_updated_at"
    t.datetime "time"
    t.datetime "created_on",       :null => false
    t.datetime "updated_on",       :null => false
    t.string   "caption"
    t.float    "aspect_ratio"
    t.text     "pic_meta"
  end

  add_index "photos", ["occasion_id"], :name => "index_photos_on_occasion_id"
  add_index "photos", ["user_id"], :name => "index_photos_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "password"
    t.string   "mobile_number"
    t.string   "email"
    t.string   "status"
    t.string   "auth_token"
    t.string   "campaign"
    t.string   "app_version",             :limit => 75
    t.datetime "registered_on"
    t.datetime "last_active_on"
    t.datetime "created_on",                            :null => false
    t.datetime "updated_on",                            :null => false
    t.string   "push_token"
    t.string   "notification_preference", :limit => 20
  end

  add_index "users", ["auth_token"], :name => "index_users_on_auth_token"
  add_index "users", ["first_name"], :name => "index_users_on_first_name"
  add_index "users", ["last_name"], :name => "index_users_on_last_name"
  add_index "users", ["mobile_number"], :name => "index_users_on_mobile_number"
  add_index "users", ["status"], :name => "index_users_on_status"

end

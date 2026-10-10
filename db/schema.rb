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

ActiveRecord::Schema[8.1].define(version: 2026_10_10_105734) do
  create_table "activities", force: :cascade do |t|
    t.string "target_kind"
    t.string "target_id"
    t.string "target_name"
    t.string "action"
    t.json "payload"
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source", default: "dashboard", null: false
    t.integer "control_event_id"
    t.index ["control_event_id"], name: "index_activities_on_control_event_id"
  end

  create_table "bridge_pairings", force: :cascade do |t|
    t.string "bridge", null: false
    t.string "app_key", null: false
    t.string "client_key"
    t.string "bridge_id"
    t.datetime "paired_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "control_binding_steps", force: :cascade do |t|
    t.integer "control_binding_id", null: false
    t.integer "position", null: false
    t.string "scene_type", null: false
    t.string "scene_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_binding_id", "position"], name: "index_control_binding_steps_on_control_binding_id_and_position", unique: true
    t.index ["control_binding_id"], name: "index_control_binding_steps_on_control_binding_id"
  end

  create_table "control_bindings", force: :cascade do |t|
    t.string "control_id", null: false
    t.string "gesture", null: false
    t.string "action", null: false
    t.string "target_type"
    t.string "target_id"
    t.json "settings", default: {}, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_id", "gesture"], name: "index_control_bindings_on_control_id_and_gesture", unique: true
    t.index ["control_id"], name: "index_control_bindings_on_control_id"
    t.index ["target_type", "target_id"], name: "index_control_bindings_on_target_type_and_target_id"
  end

  create_table "control_events", force: :cascade do |t|
    t.string "control_id", null: false
    t.string "gesture", null: false
    t.integer "rotation_steps"
    t.string "rotation_direction"
    t.integer "duration_ms"
    t.string "bridge_event_id", null: false
    t.integer "control_binding_id"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.index ["bridge_event_id", "control_id"], name: "index_control_events_on_bridge_event_id_and_control_id", unique: true
    t.index ["control_binding_id"], name: "index_control_events_on_control_binding_id"
    t.index ["control_id"], name: "index_control_events_on_control_id"
    t.index ["occurred_at"], name: "index_control_events_on_occurred_at"
  end

  create_table "custom_scene_lights", force: :cascade do |t|
    t.integer "custom_scene_id", null: false
    t.string "light_id", null: false
    t.boolean "on", default: true, null: false
    t.decimal "brightness", precision: 5, scale: 2
    t.decimal "color_x", precision: 6, scale: 4
    t.decimal "color_y", precision: 6, scale: 4
    t.integer "mirek"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_scene_id", "light_id"], name: "index_custom_scene_lights_on_custom_scene_id_and_light_id", unique: true
    t.index ["custom_scene_id"], name: "index_custom_scene_lights_on_custom_scene_id"
    t.index ["light_id"], name: "index_custom_scene_lights_on_light_id"
  end

  create_table "custom_scenes", force: :cascade do |t|
    t.string "name", null: false
    t.string "group_id"
    t.integer "transition_ms", default: 400, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_custom_scenes_on_group_id"
  end

  create_table "cycle_states", force: :cascade do |t|
    t.integer "control_binding_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "last_pressed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_binding_id"], name: "index_cycle_states_on_control_binding_id", unique: true
  end

  create_table "floor_nets", force: :cascade do |t|
    t.string "group_id"
    t.json "points", default: [], null: false
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_floor_nets_on_group_id"
  end

  create_table "floor_objects", force: :cascade do |t|
    t.string "group_id", null: false
    t.string "kind", null: false
    t.decimal "x", precision: 5, scale: 2, null: false
    t.decimal "y", precision: 5, scale: 2, null: false
    t.decimal "w", precision: 5, scale: 2, null: false
    t.decimal "h", precision: 5, scale: 2, null: false
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rotation", default: 0, null: false
    t.index ["group_id"], name: "index_floor_objects_on_group_id"
  end

  create_table "hue_controls", id: :string, force: :cascade do |t|
    t.string "device_id", null: false
    t.string "kind", null: false
    t.integer "control_number"
    t.string "id_v1"
    t.string "last_event"
    t.datetime "last_event_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id", "kind", "control_number"], name: "index_hue_controls_on_device_id_and_kind_and_control_number", unique: true
    t.index ["device_id"], name: "index_hue_controls_on_device_id"
  end

  create_table "hue_devices", id: :string, force: :cascade do |t|
    t.string "name", null: false
    t.string "product_name"
    t.string "kind", default: "other", null: false
    t.string "id_v1"
    t.boolean "reachable", default: true, null: false
    t.integer "battery_percent"
    t.json "raw", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hue_extensions_groups", id: :string, force: :cascade do |t|
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nickname"
    t.decimal "floor_aspect", precision: 4, scale: 2, default: "1.0", null: false
    t.boolean "hidden", default: false, null: false
  end

  create_table "hue_extensions_lights", id: :string, force: :cascade do |t|
    t.string "nickname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false, null: false
    t.boolean "on_floor", default: true, null: false
    t.string "icon"
  end

  create_table "hue_extensions_scenes", id: :string, force: :cascade do |t|
    t.string "nickname"
    t.boolean "favourite", default: false, null: false
    t.boolean "hidden", default: false, null: false
    t.integer "position"
    t.boolean "made_here", default: false, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hue_group_lights", force: :cascade do |t|
    t.string "group_id", null: false
    t.string "light_id", null: false
    t.index ["group_id", "light_id"], name: "index_hue_group_lights_on_group_id_and_light_id", unique: true
    t.index ["group_id"], name: "index_hue_group_lights_on_group_id"
    t.index ["light_id"], name: "index_hue_group_lights_on_light_id"
  end

  create_table "hue_groups", id: :string, force: :cascade do |t|
    t.string "kind", null: false
    t.string "name", null: false
    t.string "grouped_light_id"
    t.string "id_v1"
    t.boolean "any_on", default: false, null: false
    t.decimal "brightness", precision: 5, scale: 2, default: "0.0", null: false
    t.json "raw", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grouped_light_id"], name: "index_hue_groups_on_grouped_light_id"
  end

  create_table "hue_lights", id: :string, force: :cascade do |t|
    t.string "device_id", null: false
    t.string "name", null: false
    t.string "id_v1"
    t.boolean "on", default: false, null: false
    t.decimal "brightness", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "color_x", precision: 6, scale: 4
    t.decimal "color_y", precision: 6, scale: 4
    t.integer "mirek"
    t.json "raw", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_hue_lights_on_device_id"
  end

  create_table "hue_listener_states", force: :cascade do |t|
    t.string "last_event_id"
    t.datetime "last_event_at"
    t.datetime "connected_at"
    t.datetime "full_sync_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "heartbeat_at"
  end

  create_table "hue_scene_actions", force: :cascade do |t|
    t.string "scene_id", null: false
    t.string "light_id", null: false
    t.boolean "on", default: true, null: false
    t.decimal "brightness", precision: 5, scale: 2
    t.decimal "color_x", precision: 6, scale: 4
    t.decimal "color_y", precision: 6, scale: 4
    t.integer "mirek"
    t.index ["light_id"], name: "index_hue_scene_actions_on_light_id"
    t.index ["scene_id", "light_id"], name: "index_hue_scene_actions_on_scene_id_and_light_id", unique: true
    t.index ["scene_id"], name: "index_hue_scene_actions_on_scene_id"
  end

  create_table "hue_scenes", id: :string, force: :cascade do |t|
    t.string "group_id", null: false
    t.string "name", null: false
    t.string "kind", default: "scene", null: false
    t.string "id_v1"
    t.json "raw", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "palette", default: {}, null: false
    t.decimal "speed", precision: 4, scale: 3
    t.boolean "auto_dynamic", default: false, null: false
    t.string "active", default: "inactive", null: false
    t.datetime "last_recalled_at"
    t.datetime "last_actions_update"
    t.string "image_id"
    t.index ["group_id"], name: "index_hue_scenes_on_group_id"
    t.index ["image_id"], name: "index_hue_scenes_on_image_id"
  end

  create_table "light_placements", force: :cascade do |t|
    t.string "group_id", null: false
    t.string "light_id", null: false
    t.decimal "x", precision: 5, scale: 2, null: false
    t.decimal "y", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "light_id"], name: "index_light_placements_on_group_id_and_light_id", unique: true
    t.index ["group_id"], name: "index_light_placements_on_group_id"
    t.index ["light_id"], name: "index_light_placements_on_light_id"
  end

  add_foreign_key "activities", "control_events"
  add_foreign_key "control_binding_steps", "control_bindings"
  add_foreign_key "control_bindings", "hue_controls", column: "control_id"
  add_foreign_key "control_events", "control_bindings"
  add_foreign_key "control_events", "hue_controls", column: "control_id"
  add_foreign_key "custom_scene_lights", "custom_scenes"
  add_foreign_key "custom_scene_lights", "hue_lights", column: "light_id"
  add_foreign_key "custom_scenes", "hue_groups", column: "group_id"
  add_foreign_key "cycle_states", "control_bindings"
  add_foreign_key "floor_nets", "hue_groups", column: "group_id", on_delete: :cascade
  add_foreign_key "floor_objects", "hue_groups", column: "group_id", on_delete: :cascade
  add_foreign_key "hue_controls", "hue_devices", column: "device_id"
  add_foreign_key "hue_extensions_groups", "hue_groups", column: "id", on_delete: :cascade
  add_foreign_key "hue_extensions_lights", "hue_lights", column: "id", on_delete: :cascade
  add_foreign_key "hue_extensions_scenes", "hue_scenes", column: "id", on_delete: :cascade
  add_foreign_key "hue_group_lights", "hue_groups", column: "group_id"
  add_foreign_key "hue_group_lights", "hue_lights", column: "light_id"
  add_foreign_key "hue_lights", "hue_devices", column: "device_id"
  add_foreign_key "hue_scene_actions", "hue_lights", column: "light_id", on_delete: :cascade
  add_foreign_key "hue_scene_actions", "hue_scenes", column: "scene_id", on_delete: :cascade
  add_foreign_key "hue_scenes", "hue_groups", column: "group_id"
  add_foreign_key "light_placements", "hue_groups", column: "group_id", on_delete: :cascade
  add_foreign_key "light_placements", "hue_lights", column: "light_id", on_delete: :cascade
end

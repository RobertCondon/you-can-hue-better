# Readability refactor

Every file in the repo, grouped into chunks that can be reviewed on their own. A chunk is
reviewed, any comments are addressed, then it is committed, pushed and ticked off here before
the next chunk starts.

## Rules

1. No comments. If code needs one, the name or the shape is wrong: rename or refactor.
2. One job per class. A class doing two things is split.
3. No magic strings or numbers. Constants, or I18n for text people read.
4. No one-letter names, and no numbered block parameters (`_1`) or `it`. Everything is spelled out.
5. Skinny controllers and models. Logic lives in plain Ruby objects.
6. Rails and Ruby conventions from the usual sources (Sandi Metz, POODR, the Rails guides,
   37signals style) wherever they make the code read better.

Applied with judgement where a rule meets something it doesn't fit: migrations are history and
only lose their comments; generated framework config keeps its shape; the API field names the
bridge sends are named once as constants and reused.

Status: `[ ]` not started, `[~]` done and waiting for review, `[x]` reviewed, committed and pushed.

## Chunk 1: Hue bridge API wrapper

How the app talks to the bridge: configuration, the HTTP connection, responses, commands,
the event stream, first-run pairing, and colour conversion.

- [x] `app/services/hue.rb`
- [x] `app/services/hue/error.rb`
- [x] `app/services/hue/config.rb`
- [x] `app/services/hue/client.rb`
- [x] `app/services/hue/resource_type.rb` (new)
- [x] `app/services/hue/resources/resource.rb` (new: `all`, `find`)
- [x] `app/services/hue/resources/updatable.rb` (new: `update`)
- [x] `app/services/hue/resources/renamable.rb` (new: `rename`)
- [x] `app/services/hue/resources/scenes.rb` (new: adds `recall`)
- [x] `app/services/hue/resources/` lights, grouped lights, rooms, zones, devices, smart scenes, buttons, relative rotaries, zigbee connectivity, device power (new)
- [x] `app/services/hue/scene_recall.rb` (new)
- [x] `app/services/hue/bridge_http.rb` (new)
- [x] `app/services/hue/persistent_connection.rb` (new, from the client)
- [x] `app/services/hue/clip_response.rb` (new, from the client)
- [x] `app/services/hue/command_result.rb` (new)
- [x] `app/services/hue/json_http.rb` (new, from the pairer)
- [x] `app/services/hue/bridge_discovery.rb` (new, from the pairer)
- [x] `app/services/hue/link_button_pairing.rb` (new, from the pairer)
- [x] `app/services/hue/bridge_connector.rb` (new, from the setup controller)
- [x] `app/services/hue/pairer.rb` (removed)
- [x] `app/services/hue/event_stream.rb`
- [x] `app/services/hue/event_stream/parser.rb` (new)
- [x] `app/services/hue/event_stream/message.rb` (new)
- [x] `app/services/hue/color.rb`
- [x] `app/services/hue/color/srgb.rb` (new)
- [x] `app/services/hue/color/cie.rb` (new)
- [x] `app/services/hue/color/white_temperature.rb` (new)
- [x] `app/services/hue/color/hue_angle.rb` (new)
- [x] `app/models/bridge_pairing.rb`
- [x] `app/controllers/setup_controller.rb`
- [x] `config/locales/en.yml` (setup messages)
- [x] `test/services/hue/color_test.rb`
- [x] `test/fixtures/files/color_baseline.json` (new)
- [x] `test/services/hue/event_stream_test.rb`
- [x] `test/services/hue/clip_response_test.rb` (new)
- [x] `test/services/hue/client_test.rb` (new)
- [x] `test/services/hue/config_test.rb` (new)
- [x] `test/services/hue/bridge_discovery_test.rb` (new)
- [x] `test/services/hue/link_button_pairing_test.rb` (new, replaces the pairer test)
- [x] `test/controllers/setup_controller_test.rb`
- [x] `test/test_helper.rb`
- [x] `test/support/fake_json_http.rb` (new)
- [x] `test/support/fake_bridge.rb` (new: fakes the bridge's HTTP connection, replaces `fake_hue_client.rb`; the fixture data is tidied in chunk 2)

Touched only to follow the new API, reviewed fully in their own chunk: `hue/sync.rb`, `hue/mirror.rb`,
`undo_action.rb`, the light and room names controllers, `hue/listener.rb`,
`hue/listener_state.rb`, `activity.rb`, `setup/show.html.erb`, and the lights, rooms, scenes,
undos and floor paints controllers.

## Chunk 2: Keeping the mirror in step

Full sync, applying live events, the listener thread, and pushing changes to open pages.

- [ ] `app/services/hue/sync.rb`
- [ ] `app/services/hue/mirror.rb`
- [ ] `app/services/hue/listener.rb`
- [ ] `app/services/house_broadcast.rb`
- [ ] `lib/puma/plugin/hue_listener.rb`
- [ ] `lib/tasks/hue.rake`
- [ ] `test/services/hue/sync_test.rb`
- [ ] `test/services/hue/mirror_test.rb`
- [ ] `test/services/hue/listener_test.rb`
- [ ] `test/services/house_broadcast_test.rb`
- [ ] `test/controllers/live_update_test.rb`
- [ ] `test/support/fake_bridge.rb` (fixture data)

## Chunk 3: Mirror and extension models

The `hue_*` tables the bridge owns and the `hue_extensions_*` tables the app owns.

- [ ] `app/models/application_record.rb`
- [ ] `app/models/hue/record.rb`
- [ ] `app/models/hue/device.rb`
- [ ] `app/models/hue/light.rb`
- [ ] `app/models/hue/group.rb`
- [ ] `app/models/hue/group_light.rb`
- [ ] `app/models/hue/scene.rb`
- [ ] `app/models/hue/scene_action.rb`
- [ ] `app/models/hue/control.rb`
- [ ] `app/models/hue/listener_state.rb`
- [ ] `app/models/hue_extensions/record.rb`
- [ ] `app/models/hue_extensions/group.rb`
- [ ] `app/models/hue_extensions/light.rb`
- [ ] `app/models/hue_extensions/scene.rb`
- [ ] `test/models/hue/scene_test.rb`
- [ ] `test/models/hue/listener_state_test.rb`
- [ ] `test/models/hue_extensions/group_test.rb`

## Chunk 4: The house snapshot, activity and undo

The read model the pages are drawn from, the command log, and Undo.

- [ ] `app/models/house.rb`
- [ ] `app/models/house/light.rb`
- [ ] `app/models/house/room.rb`
- [ ] `app/models/house/scene.rb`
- [ ] `app/models/activity.rb`
- [ ] `app/models/undo_action.rb`
- [ ] `test/models/house_test.rb`
- [ ] `test/models/house_light_test.rb`
- [ ] `test/models/house_light_icon_test.rb`
- [ ] `test/models/house_light_reachable_test.rb`

## Chunk 5: Remote controls and the bridge's old rules

Switch and dial bindings, press logging, and the import of the bridge's v1 rules.

- [ ] `app/models/control_binding.rb`
- [ ] `app/models/control_binding_step.rb`
- [ ] `app/models/control_event.rb`
- [ ] `app/models/cycle_state.rb`
- [ ] `app/models/custom_scene.rb`
- [ ] `app/models/custom_scene_state.rb`
- [ ] `app/services/legacy_rules_import.rb`
- [ ] `test/models/control_binding_test.rb`
- [ ] `test/services/legacy_rules_import_test.rb`

## Chunk 6: The floor

Placements, walls and furniture, nets and the outline, paint, and their endpoints.

- [ ] `app/models/floor.rb`
- [ ] `app/models/floor_net.rb`
- [ ] `app/models/floor_object.rb`
- [ ] `app/models/light_placement.rb`
- [ ] `app/controllers/floors_controller.rb`
- [ ] `app/controllers/floor_nets_controller.rb`
- [ ] `app/controllers/floor_objects_controller.rb`
- [ ] `app/controllers/floor_paints_controller.rb`
- [ ] `test/controllers/floors_controller_test.rb`
- [ ] `test/controllers/floor_nets_controller_test.rb`
- [ ] `test/controllers/floor_objects_controller_test.rb`
- [ ] `test/controllers/floor_paints_controller_test.rb`

## Chunk 7: Lights, rooms and scenes controllers

- [ ] `app/controllers/application_controller.rb`
- [ ] `app/controllers/dashboard_controller.rb`
- [ ] `app/controllers/lights_controller.rb`
- [ ] `app/controllers/light_names_controller.rb`
- [ ] `app/controllers/room_names_controller.rb`
- [ ] `app/controllers/rooms_controller.rb`
- [ ] `app/controllers/scenes_controller.rb`
- [ ] `app/controllers/undos_controller.rb`
- [ ] `app/controllers/visibility_controller.rb`
- [ ] `app/helpers/application_helper.rb`
- [ ] `app/jobs/application_job.rb`
- [ ] `test/controllers/dashboard_controller_test.rb`
- [ ] `test/controllers/lights_controller_test.rb`
- [ ] `test/controllers/names_controller_test.rb`
- [ ] `test/controllers/pinned_light_test.rb`
- [ ] `test/controllers/rooms_controller_test.rb`
- [ ] `test/controllers/scenes_controller_test.rb`
- [ ] `test/controllers/tiles_and_undo_test.rb`
- [ ] `test/controllers/visibility_test.rb`

## Chunk 8: Views

- [ ] `app/views/layouts/application.html.erb`
- [ ] `app/views/shared/_editor.html.erb`
- [ ] `app/views/shared/_flash.html.erb`
- [ ] `app/views/shared/_nav.html.erb`
- [ ] `app/views/shared/_undo.html.erb`
- [ ] `app/views/dashboard/show.html.erb`
- [ ] `app/views/dashboard/dev.html.erb`
- [ ] `app/views/dashboard/unreachable.html.erb`
- [ ] `app/views/dashboard/_presses.html.erb`
- [ ] `app/views/dashboard/_status.html.erb`
- [ ] `app/views/dashboard/_summary.html.erb`
- [ ] `app/views/dashboard/_visibility.html.erb`
- [ ] `app/views/activities/_activity.html.erb`
- [ ] `app/views/rooms/_room.html.erb`
- [ ] `app/views/rooms/_head.html.erb`
- [ ] `app/views/lights/_light.html.erb`
- [ ] `app/views/lights/_icon.html.erb`
- [ ] `app/views/lights/_panel.html.erb`
- [ ] `app/views/lights/_pin.html.erb`
- [ ] `app/views/scenes/index.html.erb`
- [ ] `app/views/scenes/show.html.erb`
- [ ] `app/views/scenes/_card.html.erb`
- [ ] `app/views/floors/show.html.erb`
- [ ] `app/views/floors/_floor.html.erb`
- [ ] `app/views/floors/_light.html.erb`
- [ ] `app/views/floors/_object.html.erb`
- [ ] `app/views/setup/show.html.erb`
- [ ] `app/views/pwa/manifest.json.erb`
- [ ] `app/views/pwa/service-worker.js`
- [ ] `config/locales/en.yml`

## Chunk 9: JavaScript libraries

- [ ] `app/javascript/application.js`
- [ ] `app/javascript/lib/busy.js`
- [ ] `app/javascript/lib/hue_color.js`
- [ ] `app/javascript/lib/floor_camera.js`
- [ ] `app/javascript/lib/floor_light.js`

## Chunk 10: Stimulus controllers for lights and rooms

- [ ] `app/javascript/controllers/application.js`
- [ ] `app/javascript/controllers/index.js`
- [ ] `app/javascript/controllers/autosave_controller.js`
- [ ] `app/javascript/controllers/color_picker_controller.js`
- [ ] `app/javascript/controllers/editor_controller.js`
- [ ] `app/javascript/controllers/light_controller.js`
- [ ] `app/javascript/controllers/light_panel_controller.js`
- [ ] `app/javascript/controllers/pinned_controller.js`
- [ ] `app/javascript/controllers/room_controller.js`
- [ ] `app/javascript/controllers/rooms_controller.js`
- [ ] `app/javascript/controllers/tile_controller.js`
- [ ] `app/javascript/controllers/toast_controller.js`

## Chunk 11: The floor's Stimulus controller

At 700 lines it is several controllers in one: camera, editing, nets, paint and the light panel.

- [ ] `app/javascript/controllers/floor_controller.js`

## Chunk 12: Stylesheet

- [ ] `app/assets/stylesheets/application.css`

## Chunk 13: Configuration and deployment

- [ ] `config/routes.rb`
- [ ] `config/application.rb`
- [ ] `config/environments/production.rb`
- [ ] `config/database.yml`
- [ ] `config/cable.yml`
- [ ] `config/importmap.rb`
- [ ] `config/boot.rb`
- [ ] `config/environment.rb`
- [ ] `config/ci.rb`
- [ ] `config/bundler-audit.yml`
- [ ] `config/hue.example.json`
- [ ] `Gemfile`
- [ ] `Dockerfile`
- [ ] `compose.yaml`
- [ ] `bin/docker-entrypoint`
- [ ] `bin/ci`
- [ ] `.dockerignore`
- [ ] `.gitignore`
- [ ] `db/seeds.rb`

## Chunk 14: Migrations

Comments removed only; the migrations have already run and stay as written.

- [ ] `db/migrate/20261006090839_create_activities.rb`
- [ ] `db/migrate/20261006094534_create_hue_mirror_tables.rb`
- [ ] `db/migrate/20261006094535_create_remote_control_tables.rb`
- [ ] `db/migrate/20261006100247_add_heartbeat_to_hue_listener_states.rb`
- [ ] `db/migrate/20261006104306_create_hue_extensions_groups.rb`
- [ ] `db/migrate/20261006105207_add_nicknames_to_hue_extensions.rb`
- [ ] `db/migrate/20261006130852_add_scene_detail_to_hue_scenes.rb`
- [ ] `db/migrate/20261006131813_create_light_placements.rb`
- [ ] `db/migrate/20261006133032_create_floor_objects.rb`
- [ ] `db/migrate/20261006134151_add_rotation_to_floor_objects.rb`
- [ ] `db/migrate/20261007105910_create_floor_nets.rb`
- [ ] `db/migrate/20261007110659_create_undo_actions.rb`
- [ ] `db/migrate/20261007222826_add_visibility_to_extensions.rb`
- [ ] `db/migrate/20261008020737_create_bridge_pairings.rb`

## Chunk 15: Docs

- [ ] `README.md`
- [ ] `docs/HUE_NOTES.md`
- [ ] `docs/DB_DESIGN.md`
- [ ] `docs/SCENES_PLAN.md`

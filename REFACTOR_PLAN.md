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

Status: `[ ]` not started, `[~]` done and waiting for review, `[x]` reviewed, committed and pushed, `[-]` skipped.

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

- [x] `app/services/hue/payloads/` resource, light, grouped light, group, device, scene, button, relative rotary, zigbee connectivity, device power (new: each bridge JSON field named once)
- [x] `app/services/hue/sync.rb`
- [x] `app/services/hue/sync/bridge_snapshot.rb` (new)
- [x] `app/services/hue/sync/step.rb` and device, light, group, membership, scene, control steps (new, from the sync)
- [x] `app/services/hue/mirror.rb`
- [x] `app/services/hue/mirror/event.rb` (new)
- [x] `app/services/hue/mirror/changes.rb` (new, replaces the Changes struct)
- [x] `app/services/hue/mirror/applier.rb` and light, grouped light, button, rotary, scene, connectivity, power appliers (new, from the mirror)
- [x] `app/services/hue/mirror/press_recorder.rb` (new)
- [x] `app/services/hue/listener.rb`
- [x] `app/services/hue/listener/backoff.rb` (new)
- [x] `app/services/hue/listener/batch_handler.rb` (new, from the listener)
- [x] `app/services/house_broadcast.rb`
- [x] `app/services/house_broadcast/targets.rb` (new: the page element ids live updates aim at)
- [x] `app/services/house_broadcast/change_broadcast.rb` (new, from the broadcaster)
- [x] `app/services/legacy_rules_import/report.rb` (new, from the rake task)
- [x] `lib/puma/plugin/hue_listener.rb`
- [x] `lib/tasks/hue.rake`
- [x] `test/services/hue/sync_test.rb`
- [x] `test/services/hue/mirror_test.rb`
- [x] `test/services/hue/listener_test.rb`
- [x] `test/services/house_broadcast_test.rb`
- [x] `test/controllers/live_update_test.rb`
- [x] `test/support/fake_bridge.rb` (fixture data)

Touched only to follow the new API, reviewed fully in their own chunk: named kind constants added
to `hue/group.rb`, `hue/scene.rb` and `hue/control.rb`.

## Chunk 3: Mirror and extension models

The `hue_*` tables the bridge owns and the `hue_extensions_*` tables the app owns.

- [x] `app/models/application_record.rb` (no change needed)
- [x] `app/models/hue/record.rb`
- [x] `app/models/hue/device.rb` (unused `remotes` and `remote?` removed)
- [x] `app/models/hue/light.rb`
- [x] `app/models/hue/group.rb`
- [x] `app/models/hue/group_light.rb`
- [x] `app/models/hue/scene.rb`
- [x] `app/models/hue/scene_action.rb`
- [x] `app/models/hue/control.rb` (unused `by_bridge_id` removed)
- [x] `app/models/hue/listener_state.rb` (`as_of` renamed `mirror_current_as_of`)
- [x] `app/models/hue_extensions/record.rb` (shared nickname and boolean handling)
- [x] `app/models/hue_extensions/group.rb`
- [x] `app/models/hue_extensions/light.rb`
- [x] `app/models/hue_extensions/scene.rb`
- [x] `app/services/hue/light_snapshot.rb` (new: one builder for a light and for a scene's light)
- [x] `app/services/hue/scene_action_rebuild.rb` (new, from the scene model)
- [x] `app/services/hue/device_classifier.rb` (new, from the device model)
- [x] `app/services/hue/payloads/scene.rb`, `scene_action.rb`, `palette.rb` (scene fields, actions and palette read from the payload; gamut, archetype and product archetype added to the light and device payloads)
- [x] `config/locales/en.yml` (control labels)
- [x] `test/models/hue/scene_test.rb`
- [x] `test/models/hue/listener_state_test.rb`
- [x] `test/models/hue/device_classifier_test.rb` (new)
- [x] `test/models/hue_extensions/group_test.rb` (no change needed)
- [x] `test/models/hue_extensions/light_test.rb` (new)

Touched only to follow the new API, reviewed fully in their own chunk: `dashboard/_status.html.erb`
and `visibility_controller.rb`.

## Chunk 4: The house snapshot, activity and undo

The read model the pages are drawn from, the command log, and Undo.

- [x] `app/models/house.rb` (now just rooms, lights and lookups; `everything:` renamed `include_hidden:`; unused `everything?` removed)
- [x] `app/models/house/loader.rb` (new: refresh, query, hide, order)
- [x] `app/models/house/room_builder.rb` (new)
- [x] `app/models/house/room_order.rb` (new)
- [x] `app/models/house/light.rb` (unused `from_api` removed)
- [x] `app/models/house/light_tile.rb` (new: tile colours and inks, from the light)
- [x] `app/models/house/light_icon.rb` (new, from the light)
- [x] `app/models/house/room.rb`
- [x] `app/models/house/scene.rb` (unused `from_api` removed)
- [x] `app/models/activity.rb`
- [x] `app/services/activity_recorder.rb` (new, from the activity model)
- [x] `app/models/undo_action.rb`
- [x] `app/services/undo/light_state.rb`, `capture.rb`, `restore.rb` (new, from the undo model)
- [x] `config/locales/en.yml` (light levels and room summaries)
- [x] `test/models/house_test.rb`
- [x] `test/models/house_light_test.rb` (now also holds the icon and reachability tests)
- [x] `test/models/house_light_icon_test.rb` (removed, merged)
- [x] `test/models/house_light_reachable_test.rb` (removed, merged)
- [x] `test/services/activity_recorder_test.rb` (new)

Touched only to follow the new API, reviewed fully in their own chunk: every controller that logs
activity or captures undo, `dashboard_controller.rb`, `house_broadcast/change_broadcast.rb`,
`hue/scene_action.rb`, `hue/color.rb` (the shared warm white), and `tiles_and_undo_test.rb`.

## Chunk 5: Remote controls and the bridge's old rules

Switch and dial bindings, press logging, and the import of the bridge's v1 rules.

- [x] `app/models/control_binding.rb` (named gestures and actions; validation messages in the locale file)
- [x] `app/models/control_binding_step.rb`
- [x] `app/models/control_event.rb`
- [x] `app/models/cycle_state.rb`
- [x] `app/services/control_bindings/scene_cycle.rb` (new, from the cycle state; `take!` and `peek` become `advance!` and `upcoming_step`)
- [x] `app/models/custom_scene.rb`
- [x] `app/services/custom_scene_capture.rb` (new, from the custom scene)
- [x] `app/models/custom_scene_state.rb`
- [x] `app/services/legacy_rules_import.rb`
- [x] `app/services/legacy_rules_import/` addresses, rule, v1 units, outcome, button importer, rotary importer (new, from the import)
- [x] `app/services/legacy_rules_import/report.rb` (follows the new skip record)
- [x] `config/locales/en.yml` (binding validation messages)
- [x] `test/models/control_binding_test.rb`
- [x] `test/services/legacy_rules_import_test.rb`

Touched only to follow the new API, reviewed fully in its own chunk: `hue/payloads/relative_rotary.rb`
now uses the binding's rotation gesture constants.

## Chunk 6: The floor

Placements, walls and furniture, nets and the outline, paint, and their endpoints.

- [x] `app/models/floor.rb`
- [x] `app/models/floor/spot_layout.rb` (new: placed spots and the waiting row, from the floor)
- [x] `app/models/floor_net.rb`
- [x] `app/models/floor_object.rb` (`add!` and `place!` moved out; unknown kinds raise their own error)
- [x] `app/models/light_placement.rb` (`map_for` renamed `positions_on`)
- [x] `app/services/floor_coordinates.rb` (new: the one rule for clamping and rounding floor percentages)
- [x] `app/services/floor_polygon.rb` (new: a net's centre and bounds)
- [x] `app/services/floor_nets/points_param.rb`, `drawing.rb` (new: reading points, one outline per house)
- [x] `app/services/floor_objects/creation.rb`, `placement.rb` (new, from the floor object)
- [x] `app/services/floor_paint.rb` (new, from the paint controller)
- [x] `app/controllers/floors_controller.rb`
- [x] `app/controllers/floor_nets_controller.rb`
- [x] `app/controllers/floor_objects_controller.rb`
- [x] `app/controllers/floor_paints_controller.rb`
- [x] `config/locales/en.yml` (floor and paint text; duplicate blocks merged)
- [x] `test/controllers/floors_controller_test.rb`
- [x] `test/controllers/floor_nets_controller_test.rb` (no change needed)
- [x] `test/controllers/floor_objects_controller_test.rb`
- [x] `test/controllers/floor_paints_controller_test.rb`
- [x] `test/models/floor_net_test.rb` (new)

Touched only to follow the new API, reviewed fully in their own chunk: `hue/light.rb` (the white
range bulbs accept) and `hue_extensions/group.rb` (setting the floor's shape).

## Chunk 7: Lights, rooms and scenes controllers

- [x] `app/controllers/application_controller.rb` (`settle` renamed `wait_for_bridge_to_settle`)
- [x] `app/controllers/concerns/toast_streams.rb` (new: every toast in one place)
- [x] `app/controllers/concerns/house_section_streams.rb` (new: replaces `render_rooms` and the inheritance from `RoomsController`)
- [x] `app/controllers/concerns/light_streams.rb` (new: a light's tiles, room heads, panel and pin)
- [x] `app/controllers/dashboard_controller.rb`
- [x] `app/controllers/lights_controller.rb`
- [x] `app/controllers/light_names_controller.rb`
- [x] `app/controllers/room_names_controller.rb`
- [x] `app/controllers/rooms_controller.rb`
- [x] `app/controllers/scenes_controller.rb` (no longer inherits from `RoomsController`)
- [x] `app/controllers/undos_controller.rb` (no longer inherits from `RoomsController`)
- [x] `app/controllers/visibility_controller.rb`
- [x] `app/services/house_commands/` outcome, undoable, room switch, scene recall, undo replay (new, from the controllers)
- [x] `app/services/light_command.rb` (new, from the lights controller)
- [x] `app/services/bridge_rename.rb` (new, shared by the two names controllers)
- [x] `app/services/scenes_by_room.rb`, `scene_preview.rb` (new, from the scenes controller)
- [x] `app/helpers/application_helper.rb` (no change needed)
- [x] `app/jobs/application_job.rb` (generated comments removed)
- [x] `config/locales/en.yml` (toasts, undo descriptions)
- [x] `test/controllers/dashboard_controller_test.rb`
- [x] `test/controllers/lights_controller_test.rb`
- [x] `test/controllers/names_controller_test.rb` (no change needed)
- [x] `test/controllers/pinned_light_test.rb` (no change needed)
- [x] `test/controllers/rooms_controller_test.rb` (no change needed)
- [x] `test/controllers/scenes_controller_test.rb` (no change needed)
- [x] `test/controllers/tiles_and_undo_test.rb` (no change needed)
- [x] `test/controllers/visibility_test.rb` (no change needed)
- [x] `test/services/light_command_test.rb` (new)

Touched only to follow the new API, reviewed fully in its own chunk: `house_broadcast/targets.rb`
gains the flash and editor error targets; `floor_paints_controller.rb` uses the new toasts.

## Chunk 8: Views

Every view was rendered before and after and the HTML compared: the pages are identical apart
from the setup form's new picker attributes and quotes now escaped as entities.

- [x] `app/views/layouts/application.html.erb`
- [x] `app/views/shared/_editor.html.erb`
- [x] `app/views/shared/_flash.html.erb`
- [x] `app/views/shared/_nav.html.erb`
- [x] `app/views/shared/_undo.html.erb`
- [x] `app/views/shared/icons/` chevron, power, brush, pencil, and the three view icons (new, from inline SVG)
- [x] `app/views/dashboard/_lights.html.erb` (new: the header and rooms the everyday and dev pages shared by copy)
- [x] `app/views/dashboard/show.html.erb`
- [x] `app/views/dashboard/dev.html.erb`
- [x] `app/views/dashboard/unreachable.html.erb`
- [x] `app/views/dashboard/_presses.html.erb`
- [x] `app/views/dashboard/_status.html.erb`
- [x] `app/views/dashboard/_summary.html.erb`
- [x] `app/views/dashboard/_visibility.html.erb`
- [x] `app/views/activities/_activity.html.erb`
- [x] `app/views/rooms/_room.html.erb`
- [x] `app/views/rooms/_head.html.erb`
- [x] `app/views/lights/_light.html.erb`
- [x] `app/views/lights/_icon.html.erb`
- [x] `app/views/lights/icons/` lamp, candle, spot, strip (new, from the icon's if chain)
- [x] `app/views/lights/_panel.html.erb`
- [x] `app/views/lights/_pin.html.erb`
- [x] `app/views/scenes/index.html.erb`
- [x] `app/views/scenes/show.html.erb`
- [x] `app/views/scenes/_card.html.erb`
- [x] `app/views/floors/show.html.erb`
- [x] `app/views/floors/_floor.html.erb` (split into the four below)
- [x] `app/views/floors/_filters.html.erb`, `_toolbar.html.erb`, `_paint_tray.html.erb`, `_map.html.erb` (new)
- [x] `app/views/floors/_light.html.erb`
- [x] `app/views/floors/_object.html.erb`
- [x] `app/views/setup/show.html.erb` (inline script replaced by a Stimulus controller)
- [x] `app/views/pwa/manifest.json.erb` (removed: generated, never routed)
- [x] `app/views/pwa/service-worker.js` (removed: generated, never routed)
- [x] `app/helpers/` application, navigation, lights, rooms, scenes, floors, dashboard (new view helpers)
- [x] `app/javascript/controllers/bridge_choice_controller.js` (new)
- [x] `config/locales/en.yml` (all view text)

Touched only to follow the new API, reviewed fully in their own chunk: `house_broadcast/targets.rb`
(element ids for every view), `house/light.rb` (`glow`), `house.rb` (`rooms_containing`),
`floor.rb` (`outline`), `floor_net.rb` and `floor_polygon.rb` (SVG points and the void path),
`floor_paint.rb` (the tray's whites and colours), `scene_preview.rb`, `hue/resources/renamable.rb`
(the bridge's name length) and `hue/link_button_pairing.rb` (the 30-second window).

## Chunk 9: JavaScript libraries

54 outputs of the colour, camera and geometry functions were recorded before the change and match
exactly after it, including the visibility polygons the light simulation draws from.

- [x] `app/javascript/application.js` (the deferral listener moved into `busy.js`)
- [x] `app/javascript/lib/busy.js` (unused `releaseAll` removed)
- [x] `app/javascript/lib/hue_color.js` (now re-exports the colour modules below)
- [x] `app/javascript/lib/color/srgb.js`, `cie.js`, `gamut.js`, `hsv.js`, `white_temperature.js` (new)
- [x] `app/javascript/lib/floor_camera.js` (camera fields renamed `zoom`, `offsetX`, `offsetY`; views use `width`, `height`; `toScreen` added)
- [x] `app/javascript/lib/floor_geometry.js` (new: from the light module, plus the point-in-polygon and bounding box the controller kept inline)
- [x] `app/javascript/lib/floor_light.js` (drawing only; walls use `width`, `height`, `rotation`)

Touched only to follow the new API, reviewed fully in chunk 11: `floor_controller.js` (camera
fields, wall rectangles, shared geometry, and a new saved-camera key).

## Chunk 10: Stimulus controllers for lights and rooms

Each interaction was exercised in the browser against the bridge: tile drag and toggle, pinning,
swiping, the colour wheel and white range, collapsing and arranging rooms, the rename dialog and
dismissing a toast.

- [x] `app/javascript/controllers/application.js`
- [x] `app/javascript/controllers/index.js`
- [x] `app/javascript/controllers/autosave_controller.js`
- [x] `app/javascript/controllers/color_picker_controller.js` (wheel drawing moved out)
- [x] `app/javascript/controllers/editor_controller.js` (finds its error line by target, not by id)
- [x] `app/javascript/controllers/light_controller.js`
- [x] `app/javascript/controllers/light_panel_controller.js`
- [x] `app/javascript/controllers/pinned_controller.js` (the swipe event's `dir` is now `direction`)
- [x] `app/javascript/controllers/room_controller.js`
- [x] `app/javascript/controllers/rooms_controller.js` (Edit and Done labels come from the locale file)
- [x] `app/javascript/controllers/tile_controller.js`
- [x] `app/javascript/controllers/toast_controller.js`
- [x] `app/javascript/lib/requests.js` (new: the CSRF-signed requests four controllers wrote by hand)
- [x] `app/javascript/lib/light_preview.js` (new: the brightness preview two controllers duplicated, and the colour preview)
- [x] `app/javascript/lib/color_wheel.js` (new, from the colour picker)
- [x] `app/views/dashboard/show.html.erb`, `dev.html.erb`, `shared/_editor.html.erb` (labels and the error target)
- [x] `config/locales/en.yml` (Done)

## Chunk 11: The floor's Stimulus controller

The controller stays the page's single Stimulus entry point (so the views barely change) and each
of its jobs moved into its own class. Every interaction was exercised in the browser against the
bridge: camera, lamp panel, filters and preview, lamp and object editing, nets, and paint with Undo.

- [x] `app/javascript/controllers/floor_controller.js` (700 lines to 160: wiring only)
- [x] `app/javascript/lib/floor/viewport.js` (new: camera, zoom, pan, pinch, coordinates, snapping)
- [x] `app/javascript/lib/floor/light_canvas.js` (new: reads lamps, walls and the outline, draws the light)
- [x] `app/javascript/lib/floor/selection.js` (new: the selection the object and net tools share)
- [x] `app/javascript/lib/floor/layout_editor.js` (new: edit mode, lamps, walls and furniture)
- [x] `app/javascript/lib/floor/net_editor.js` (new: drawing tools, nets, vertices, room assignment)
- [x] `app/javascript/lib/floor/scene_preview.js` (new: room filter and scene preview)
- [x] `app/javascript/lib/floor/paint_brush.js` (new: tray, brush, sweep, apply)
- [x] `app/javascript/lib/floor/lamp_panel.js` (new: the popover beside a lamp, or the dock on a phone)
- [x] `app/javascript/lib/floor/element_style.js` (new: CSS-variable helpers the classes share)
- [x] `app/views/floors/_floor.html.erb`, `app/helpers/floors_helper.rb`, `config/locales/en.yml` (the controller's text)

## Chunk 12: Stylesheet

Every element's computed style was compared with the old stylesheet swapped in, on every page and
in the main interactive states, at desktop and phone widths: identical, apart from the phone
floor's zoom buttons, which the old file's rule order had stretched down the whole map.

- [x] `app/assets/stylesheets/application.css` (removed: split into the files below)
- [x] `app/assets/stylesheets/tokens.css` (new: colours, shadows, radii, type sizes, timings, layers)
- [x] `app/assets/stylesheets/base.css`, `header.css`, `toasts.css`, `rooms.css`, `tiles.css`, `light_panel.css`, `pinned_light.css`, `scenes.css`, `dev.css` (new)
- [x] `app/assets/stylesheets/floor.css`, `floor_toolbar.css`, `floor_nets.css`, `floor_paint.css`, `floor_objects.css`, `floor_lamps.css` (new)
- [x] `app/assets/stylesheets/editor.css`, `pages.css` (new)
- [x] `app/views/layouts/application.html.erb`, `app/helpers/application_helper.rb` (the stylesheets in their load order)

## Chunk 13: Configuration and deployment

The Docker image was rebuilt and run against the bridge: healthy, every page served, listener live.

- [x] `config/routes.rb` (grouped by area)
- [x] `config/application.rb`
- [x] `config/environments/production.rb`
- [x] `config/environments/development.rb`, `test.rb` (generator comments removed)
- [x] `config/database.yml`
- [x] `config/cable.yml`
- [x] `config/importmap.rb`
- [x] `config/boot.rb`
- [x] `config/environment.rb`
- [x] `config/puma.rb` (the unused job runner removed)
- [x] `config/ci.rb` (the seed step removed with the empty seeds file)
- [x] `config/bundler-audit.yml` (the generator's placeholder CVE removed)
- [x] `config/hue.example.json` (no change needed)
- [x] `config/initializers/filter_parameter_logging.rb` (the bridge's client key and username are filtered from logs)
- [x] `config/initializers/content_security_policy.rb`, `inflections.rb`, `assets.rb` (removed: comments only, or Rails' default)
- [x] `Gemfile`, `Gemfile.lock` (unused `solid_cache`, `solid_queue`, `capybara`, `selenium-webdriver` removed)
- [x] `Dockerfile`
- [x] `compose.yaml`
- [x] `bin/docker-entrypoint`
- [x] `bin/ci` (no change needed)
- [x] `.dockerignore`
- [x] `.gitignore`
- [x] `db/seeds.rb` (removed: comments only)
- [x] `app/services/hue/event_stream.rb`, `test/services/hue/listener_test.rb` (the two style-checker offences)

## Chunk 14: Migrations

Skipped at Rob's request: the migrations have already run and stay as written.

- [-] `db/migrate/20261006090839_create_activities.rb`
- [-] `db/migrate/20261006094534_create_hue_mirror_tables.rb`
- [-] `db/migrate/20261006094535_create_remote_control_tables.rb`
- [-] `db/migrate/20261006100247_add_heartbeat_to_hue_listener_states.rb`
- [-] `db/migrate/20261006104306_create_hue_extensions_groups.rb`
- [-] `db/migrate/20261006105207_add_nicknames_to_hue_extensions.rb`
- [-] `db/migrate/20261006130852_add_scene_detail_to_hue_scenes.rb`
- [-] `db/migrate/20261006131813_create_light_placements.rb`
- [-] `db/migrate/20261006133032_create_floor_objects.rb`
- [-] `db/migrate/20261006134151_add_rotation_to_floor_objects.rb`
- [-] `db/migrate/20261007105910_create_floor_nets.rb`
- [-] `db/migrate/20261007110659_create_undo_actions.rb`
- [-] `db/migrate/20261007222826_add_visibility_to_extensions.rb`
- [-] `db/migrate/20261008020737_create_bridge_pairings.rb`

## Chunk 15: Docs

- [x] `README.md` (rewritten around how the app is organised now; the old one named classes that no longer exist)
- [x] `docs/HUE_NOTES.md` (rewritten: it had become Rails' generated placeholder README)
- [x] `docs/DB_DESIGN.md` (status, table names, the extension and app tables brought up to date against the schema)
- [x] `docs/SCENES_PLAN.md` (marked as the plan the scenes and floor were built from, with what is built)
- [x] `design/README.md` and the preview pages (the stylesheet rebuild and the renamed colour tokens)
- [x] `lib/tasks/design.rake` (new: rebuilds the design previews' stylesheet from the split files)

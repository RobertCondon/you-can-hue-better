# Database design: event-fed mirror + app-owned remote control

Written 2026-10-06. Companion to HUE_NOTES.md. Everything here was checked against the real bridge.

**Status:** the tables exist, the dashboard reads from the mirror, and `Hue::Listener` keeps the
mirror fresh from the event stream (started with the server by a Puma plugin). Presses are logged to
`control_events` but **not acted on**: the bridge's own rules still drive the switches and the dial,
and nothing reads `control_bindings` yet. The dispatcher is the next piece.

Naming: mirror tables are prefixed `hue_` with models under `Hue::` (`Hue::Device`, `Hue::Light`,
`Hue::Group`, `Hue::Scene`, `Hue::Control`, `Hue::ListenerState`). The bindings model is
`ControlBinding` (table `control_bindings`) because Ruby's core `Binding` class takes the plain name.

## What the bridge told us

- The **event stream** (`GET /eventstream/clip/v2`, SSE) pushes partial diffs: only changed fields,
  each batch with an `id`, `creationtime`, and `type: update`. Light changes arrive within ~1s, and
  the bridge also streams recomputed `grouped_light` brightness for every group the light is in.
- The switches are driven by **71 legacy v1 rules** on the bridge (`data/v1-rules.json`), not v2
  behavior instances. The v2 behavior instances are only the time-based ones (wake up, go to sleep,
  bathroom timers).
- The **Tap Dial** (device `b3231815…`, v1 sensors 18 buttons / 17 rotary) currently does:
  - Button 1 short: cycle 8 scenes on zone "Tap dail lights?" (Cancun, Nutcracker, Fall harvest,
    Nightlight, Palm Beach, Relax, Sleepy, Tropical twilight). Long: zone off.
    Cycle position lives in a CLIP "status" sensor and resets to 0 after 10s idle.
  - Button 2 short: cycle 8 scenes on Living room lamps (also turns Kitchen on if LR is off).
    Long: Living room off.
  - Button 3 short: Fancy dinner table light bright cool white. Long: same light at 1%.
  - Button 4: unused.
  - Rotary: brightness delta on the zone, scaled across 11 speed bands (±6 … ±254 on the 0-254
    scale); turning when the zone is off turns it on at 50% (fast) or 2% (slow).
- Dimmer switches: button 1 toggle, 2/3 brightness ±30 (long ±56), 4 cycles 5-6 scenes.
- Button resources report `initial_press`, `repeat`, `short_release`, `long_press`, `long_release`.
  Rotary reports `{action, rotation: {direction, steps, duration}}`.

## Principles

1. **Two kinds of table, never mixed.** *Mirror* tables are a cache of bridge state, written only by
   the listener. *App* tables are things the bridge cannot represent, written by controllers and jobs.
2. **Hue ids are the primary keys of mirror rows** (string UUIDs). No surrogate ids to translate.
3. **Partial upserts.** Events carry only changed fields, so the listener merges; it never replaces.
   A `raw` JSON column keeps the last full resource for anything without a column.
4. **One process writes the mirror.** SQLite in WAL mode (Rails 8 default) lets Puma read while
   the listener writes. `busy_timeout` is already set in database.yml.
5. **Every command is attributable.** `activities` gains a `source` and a link to the press that
   caused it, so "why did the lights change at 23:14" is always answerable.

## Mirror tables (listener-owned, `hue_` prefix)

```
hue_devices
  id              string PK      Hue device id
  name            string
  product_name    string         "Hue tap dial switch", "Hue color lamp", ...
  kind            string         light | dimmer | dial | bridge | other   (derived from product)
  id_v1           string         "/sensors/18", "/lights/7" (handy for the legacy rules)
  reachable       boolean        from zigbee_connectivity status
  battery_percent integer null   from device_power (switches only)
  raw             json
  updated_at

lights
  id              string PK      Hue light service id
  device_id       string FK devices
  name            string
  on              boolean
  brightness      decimal(5,2)   0-100
  color_x         decimal(6,4) null
  color_y         decimal(6,4) null
  mirek           integer null
  raw             json
  updated_at

hue_groups                            rooms, zones and bridge_home, one table
  id              string PK      Hue room/zone id
  kind            string         room | zone | home
  name            string
  grouped_light_id string        the id you PUT to; indexed
  id_v1           string         "/groups/85"
  any_on          boolean        from grouped_light events
  brightness      decimal(5,2)   bridge-computed average, from grouped_light events
  raw             json
  updated_at

hue_group_lights                      membership, rebuilt on full sync
  group_id        string FK groups
  light_id        string FK lights
  PK (group_id, light_id)

hue_scenes                            bridge-stored scenes, incl. smart scenes
  id              string PK
  group_id        string FK groups
  name            string
  kind            string         scene | smart_scene
  raw             json
  updated_at

hue_controls                          one row per button or rotary service on a switch
  id              string PK      Hue button / relative_rotary service id
  device_id       string FK devices
  kind            string         button | rotary
  control_number  integer        1-4 as printed on the device (metadata.control_id); null for rotary
  last_event      string null
  last_event_at   datetime null
  unique (device_id, kind, control_number)

hue_listener_states                   single row, read by the dashboard for "last heard 3s ago"
  id              integer PK (always 1)
  last_event_id   string
  last_event_at   datetime
  connected_at    datetime null
  full_sync_at    datetime
```

Full sync (on boot, on reconnect, and every 10 minutes as belt and braces) reads device, light,
room, zone, scene, button, relative_rotary, zigbee_connectivity, device_power and rebuilds
everything, including `group_lights`. Between syncs the stream keeps rows current.

## Extension tables (app-owned, one-to-one with a mirror row)

`hue_extensions_*` tables share their primary key with the mirror row they extend and are never
written by sync. `hue_extensions_groups` (model `HueExtensions::Group`) holds what the app knows
about a room or zone: today its dashboard `position`; later hidden, nickname, default scene.
`Hue::Group#extension` reaches it. A room deleted on the bridge cascades its extension row away.

## App tables (controller / job owned)

```
custom_scenes
  id              integer PK
  name            string
  group_id        string FK groups null     the room/zone it belongs to in the UI; null = whole house
  hue_scene_id    string FK scenes null     set when the scene has been pushed to the bridge
  transition_ms   integer default 400
  created_at, updated_at

custom_scene_states               one row per light the scene touches; lights not listed are untouched
  custom_scene_id integer FK
  light_id        string FK lights
  on              boolean
  brightness      decimal(5,2) null
  color_x, color_y decimal null
  mirek           integer null
  PK (custom_scene_id, light_id)

control_bindings                  what a control does on a given gesture (model: ControlBinding)
  id              integer PK
  control_id      string FK controls
  gesture         string         short_release | long_press | repeat | long_release | initial_press
                                 | rotate_cw | rotate_ccw
  action          string         recall_scene | cycle_scenes | toggle_group | group_on | group_off
                                 | brightness_delta | set_light | webhook | job
  target_type     string null    Group | Light
  target_id       string null
  settings        json           action-specific: {delta: 10, scale_by_rotation: true},
                                 {url: ...}, {brightness: 97, mirek: 182}, {cycle_window_s: 10}
  enabled         boolean default true
  unique (control_id, gesture)

control_binding_steps             the ordered list for cycle_scenes; recall_scene has exactly one
  control_binding_id      integer FK
  position        integer
  scene_type      string         Scene | CustomScene     (polymorphic)
  scene_id        string         Hue id or custom_scenes.id
  PK (control_binding_id, position)

cycle_states                      the "where am I in the cycle" memory the v1 rules kept in sensors
  control_binding_id      integer PK FK
  position        integer
  last_pressed_at datetime

control_events                    every press and turn, forever (cheap: a few hundred rows a week)
  id              integer PK
  control_id      string FK controls
  gesture         string
  rotation_steps  integer null
  rotation_direction string null
  duration_ms     integer null
  bridge_event_id string         for idempotency on reconnect replays
  control_binding_id      integer FK null what it resolved to, if anything
  occurred_at     datetime        bridge creationtime
  created_at
  index (occurred_at), unique (bridge_event_id, control_id)

activities                        existing, two new columns
  + source          string       dashboard | remote | schedule | api
  + control_event_id integer FK null
```

## Why these choices

- **Custom scenes are stored per light, and optionally pushed to the bridge.** Recalling a Hue
  scene is one bridge call and all bulbs transition together. Recalling by PUTting each light is N
  calls, rate-limited to ~10/s, and bulbs change one by one. So when a custom scene fits in one
  room or zone, the app creates a real Hue scene from it and stores `hue_scene_id`; recall is then
  atomic. Cross-room custom scenes fall back to per-light PUTs. The app's copy stays the editable
  source of truth, and "capture current state as a scene" is just a copy from `lights`.
- **Bindings are keyed by (control, gesture), not by device.** A dial has four buttons and a ring;
  a dimmer has four buttons. One row per gesture per control keeps the rule table flat, and the
  unique index means a gesture can do exactly one thing, which is what the Hue app also enforces.
- **cycle_states is a table, not a cache.** It is tiny, it must survive a restart mid-cycle, and
  the dashboard can show "next press gives: Relax".
- **control_events is append-only and complete.** It is the thing the bridge will never give you:
  a history of what the remotes did. It also makes the dispatcher idempotent: on reconnect the
  bridge may replay events, and the unique index drops duplicates.
- **groups holds rooms, zones and home in one table.** They differ only in membership rules, and
  the dashboard renders them identically. `kind` is enough.
- **Gesture mapping from v1.** The legacy rules fire on *press* (x000) and *hold* (x001). The import
  maps press to `short_release` so a long press no longer also triggers the short action, and hold
  to `repeat` for dimming (fires while held) or `long_press` for everything else.
- **No `rooms`/`lights` ActiveRecord classes named like today's value objects.** The plain-Ruby
  `House`, `House::Room`, `House::Light` snapshot classes stay as the view model; they get constructed from these
  tables instead of from five bridge calls. Nothing in the views changes.

## What a dial press looks like end to end

1. Bridge streams `{type: button, id: <control>, button: {button_report: {event: short_release}}}`.
2. Listener writes `control_events` (dedup on bridge_event_id), updates `controls.last_event`.
3. Dispatcher finds `bindings` for (control_id, short_release). If `cycle_scenes`: load
   `cycle_states`, reset position to 0 if `last_pressed_at` is older than `settings.cycle_window_s`,
   pick `binding_steps[position]`, advance and save.
4. Recall the scene through `Hue.client`, logged in `activities` with `source: remote` and the
   `control_event_id`.
5. The bridge streams the resulting light changes; the listener updates `lights`/`groups` and
   broadcasts Turbo updates to open dashboards.

Latency budget: event arrival ~100-300ms after the physical press, dispatch <5ms, recall ~50ms.
Comparable to the bridge's own rules.

## Rotary handling

`repeat` events arrive in bursts while turning, each with `steps` and `duration`. The
`brightness_delta` action computes `delta = sign * f(steps/duration)` with the same bands the v1
rules use, then sends one `grouped_light` PUT per event. The bridge allows ~1 group command per
second, so the dispatcher coalesces: if a PUT for the same target is in flight, accumulate the
delta and send once it returns. This mirrors what the bridge rules do implicitly.

## Migration from the bridge's rules

The bridge's v1 rules and the app must not both act on a press. Plan:

1. Seed `bindings` from `data/v1-rules.json` so day one behaviour is identical.
2. Delete the dial's v1 rules (rules 31-71, sensors 17 and 18) with `DELETE /api/<key>/rules/<id>`.
   Keep the dimmer switch rules on the bridge until their bindings are seeded too.
3. The Hue app will show the dial as "not configured". That is expected and correct.

`data/v1-rules.json` is the backup; the rules can be recreated from it if needed.

## Deliberately left out for now

- `schedules` / `automations`: the bridge's time-based behaviours still work and are fine there.
  When they move into the app they become Solid Queue recurring jobs plus one `automations` table.
- Multi-bridge, multi-home: everything assumes one bridge. Adding `bridge_id` later is mechanical.
- Entertainment / streaming API: a different protocol (UDP), out of scope.

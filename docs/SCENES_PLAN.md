# Scenes: saving the bridge's, then making our own

Written 2026-10-07. Facts below were checked against the bridge. This is the plan the scenes and
floor were built from, kept as a record of the choices made; the README describes what exists now.
Part 1 B and the floor are built. Part 2, scenes made in the app, is not.

**Built so far (2026-10-07):** Part 1 B. `hue_scenes` has the detail columns, `hue_scene_actions`
is rebuilt on sync and on scene events, the listener applies scene status in place (no full sync
per recall), `hue_extensions_scenes` exists, and `/scenes` + `/scenes/:id` show cards with a dot per
light, the palette behind, Set / Play, and the active badge. Dashboard untouched.
Floors too: `light_placements`, `hue_extensions_groups.floor_aspect`, `/rooms/:id/floor` (live, Edit
floor with drag and arrow-key nudging, snapped to 5%), and `/scenes/:id` drawn on the floor.
Floor lights also update live through the broadcast.
Revised 2026-10-07: there is one floor for the whole **house** (placements and objects keyed by
the bridge's home group), not one per room. Rooms and scenes are filters on it: a room greys out
every light outside it; a scene shows its lights as it sets them and greys out the rest.
Walls and furniture (`floor_objects`): walls block the light and bounce it (visibility polygon per
light + a mirrored virtual source per visible wall face, drawn on a canvas); boxes and rounds are
decoration. All drag, resize, rotate and delete in Edit floor, snapping to a tenth of a grid cell.
Glow radius and strength grow with brightness (sqrt for reach, linear for strength) with an
inverse-square-ish falloff and a hot core. The live floor can preview any of the room's scenes
locally (`GET /scenes/:id/floor_state`) without recalling it.

## What a bridge scene is

Every scene on the bridge (28, plus one time-based "smart scene") is already in `hue_scenes.raw`
because the sync stores the full resource. A scene has:

- **group**: exactly one room or zone. Names repeat across groups (Relax exists in three), so a
  scene is only meaningful together with its group.
- **actions**: one per light in the group, each `on` + `dimming.brightness` + either `color.xy`
  or `color_temperature.mirek`. 152 colour actions and 38 white actions across the 28 scenes.
- **palette**: a list of colours / whites the Hue app picked for the scene (every scene here has
  one, usually 5 colours + 1 white), plus `speed` and `auto_dynamic` for the animated "dynamic"
  mode where the bridge cycles lights through the palette.
- **image**: a reference to a stock picture the Hue app shows; not fetchable usefully.
- **status**: whether it is active right now, and when it was last recalled.

So "saving the current scenes" is mostly done. What's missing is making them *legible*: a shape
the UI can render and query, and a page to see them on.

## Part 1: make the bridge's scenes viewable

### Approach A: render straight from `raw`
Parse `actions` at render time into a per-light list and draw a swatch strip.
- Pro: no schema, nothing to keep in sync, ships in an afternoon.
- Con: nothing queryable ("which scenes use this light", "all scenes warmer than 2700K") without
  loading every raw blob. Every page renders from JSON parsing.
- Verdict: fine for a first screen, poor foundation for Part 2.

### Approach B: a mirror table `hue_scene_actions` (recommended)
```
hue_scene_actions          listener-owned, rebuilt from raw on sync and on scene events
  id          integer PK
  scene_id    string FK hue_scenes
  light_id    string FK hue_lights
  on          boolean
  brightness  decimal
  color_x/y   decimal null
  mirek       integer null
  unique (scene_id, light_id)
```
Same ownership rule as the other `hue_*` tables: written only by sync/listener, derived from `raw`.
- Pro: one row shape for "a light's state in a scene", queryable, joins to lights and groups.
- Pro: the same shape custom scenes need, so Part 2 can share views and the preview renderer.
- Con: one more table to keep in step; cheap, since scene edits arrive on the event stream and
  trigger a full sync already.

### Approach C: copy bridge scenes into the custom tables as "imported"
- Pro: one table for everything.
- Con: they are not ours. The Hue app edits them, the switches recall them by bridge id, and an
  imported copy drifts the moment someone touches the scene in the Hue app. Rejected.

### Storing the animated ("play") mode

A scene's static look is its `actions`. Its animated look is its **palette**: a short list of
colours and whites, each with a brightness, plus `speed` (0-1) and `auto_dynamic` (start animated
when recalled). The bridge runs the animation itself: recall with `{"recall":{"action":"dynamic_palette"}}`
and it hands each light a palette entry and keeps transitioning them at `speed`; `"active"` recalls
the static look; `"static"` freezes a running animation. `status.active` reports `inactive`,
`static` or `dynamic_palette`, so "is it playing" is just a field on the stream.

So the palette is per scene, not per light, and small (5 colours + 1 white here). Store it on the
scene row, not in `hue_scene_actions`:

```
hue_scenes  (+ columns)
  palette       json      the bridge's palette object, verbatim
  speed         decimal
  auto_dynamic  boolean
  active        string    inactive | static | dynamic_palette   (from status.active)
```

The Scenes page gets two buttons per scene: **Set** (static) and **Play** (dynamic), and the card
shows a playing badge while `active == dynamic_palette`. While a scene plays, every light change
streams in as usual, so the mirror and tiles follow the animation; broadcasts should be throttled
to a few a second per light so a 10-light animation does not flood open pages.

Custom scenes mirror the same shape: `custom_scenes.palette` (json), `speed`, `auto_dynamic`,
published verbatim when the scene is pushed to the bridge. Static-only in the first editor;
palette editing is a later screen.

### The screen
A **Scenes** page (and a tab inside each room) listing scenes per room/zone, each as a card:
name, a swatch strip of its lights in their scene colours and brightness, a "white"/"colour"
hint, whether it is the active scene, and a Recall button. Tapping a card expands the per-light
list (reusing the tile look). Active scene detection comes from `status.active` on the stream.

Per-scene app facts (favourite, nickname, hide from everyday view, position) go in a
`hue_extensions_scenes` table keyed by the scene id, like groups and lights.

## Part 2: our own scenes, stored alongside

Three places a "scene we made" can live. They are not exclusive; the question is which is the
source of truth.

### Approach 1: app-native only (`custom_scenes` + `custom_scene_states`, already designed)
Recall = one PUT per light.
- Pro: unlimited, any lights across any rooms, transitions and future features (per-light delays,
  randomisation) without asking Hue.
- Pro: already in the schema; `CustomScene.capture` snapshots the current house.
- Con: recall is N requests at ~10/s, so a 10-light scene takes about a second and bulbs change
  one after another rather than together.
- Con: invisible to the Hue app and to the bridge's own switch rules. Until the app's dispatcher
  owns the dial, a custom scene cannot be on a button.

### Approach 2: bridge-native (POST /resource/scene; app keeps only metadata)
The app is a nicer editor for scenes that live on the bridge. Verified 2026-10-07: a POST with
`type`, `metadata.name`, `group`, `actions` (and optionally `palette`, `speed`, `auto_dynamic`)
creates a scene the bridge then owns like any other; PUT edits it, DELETE removes it, and the
listener's structural sync picks each up within a second.
- Pro: atomic recall, all bulbs transition together, visible in the Hue app, usable by the bridge's
  switch rules today, dynamic palettes for free.
- Con: one group per scene, 32-char names, a bridge limit on scene count, and the Hue model is the
  ceiling: no cross-room scene without first creating a zone.
- Con: two editors (ours and the Hue app) on the same object. Fine, since the bridge is the single
  source of truth and we re-sync on every change event.

### Approach 3: hybrid, app is the editor, bridge is the executor (recommended)
Custom scenes are authored and stored in the app (`custom_scenes`). On save, the app **publishes**:
- If every light is inside one room or zone: create/update one bridge scene for that group and
  store `hue_scene_id`. Recall is one call.
- If the lights span groups: create one bridge scene per group they touch (named "<scene> · <room>")
  and recall them in sequence, or offer "make a zone for this" so it can be one scene.
- If publishing fails or the bridge is down: fall back to per-light PUTs, logged as such.
The app's copy stays editable; republish on save. Edits made to the published scene in the Hue
app are detected by the sync (the bridge scene's `last_actions_update` moves) and shown as
"changed on the bridge" with a choice to pull or overwrite.
- Pro: fast, atomic recall where it matters, and no ceiling where it doesn't.
- Pro: a published scene is a real Hue scene, so the dial's existing rules can use it right now.
- Con: the most code: publish, drift detection, and the per-group split for cross-room scenes.

## Data structures for everything except app-hosted custom scenes

Everything here follows the existing rule: `hue_*` is a mirror the listener writes, `hue_extensions_*`
is app-owned and keyed by the same id. Scenes the app creates on the bridge are ordinary mirror rows;
the only thing we remember about them is in the extension row.

### 1. `hue_scenes` gains columns (mirror)
```
  palette              json      the bridge's palette object verbatim: color[], color_temperature[], dimming[], effects[]
  speed                decimal   0..1, animation pace
  auto_dynamic         boolean   recall starts animated
  active               string    inactive | static | dynamic_palette   (status.active)
  last_recalled_at     datetime  status.last_recall
  last_actions_update  datetime  only set when the bridge sends a timestamp; on this firmware it sends
                                 an object instead, so drift detection must compare actions, not stamps
  image_id             string    public_image rid, informational
```

### 2. `hue_scene_actions` (mirror, new)
One row per light per scene, rebuilt from `raw.actions` whenever the scene row changes.
```
  id          integer PK
  scene_id    string FK hue_scenes (cascade)
  light_id    string FK hue_lights (cascade)
  on          boolean
  brightness  decimal(5,2) null
  color_x     decimal(6,4) null
  color_y     decimal(6,4) null
  mirek       integer null
  unique (scene_id, light_id)
```
Models: `Hue::Scene has_many :actions`; `Hue::SceneAction belongs_to :scene, :light`, with
`to_snapshot` returning a `House::Light`-shaped value so the tile partial can render a scene's
light exactly like a live one. `Hue::Light has_many :scene_actions` answers "which scenes use this".

### 3. `hue_extensions_scenes` (app-owned, new)
```
  id            string PK = hue scene id, FK hue_scenes (cascade)
  nickname      string null
  favourite     boolean default false
  hidden        boolean default false   keep off the everyday view
  position      integer null            order within its room's scene row
  made_here     boolean default false   created by this app's editor, not the Hue app
  notes         text null
```
Model `HueExtensions::Scene`, `Hue::Scene has_one :extension`. `made_here` is the only trace that a
bridge scene came from us; it lets the UI say "yours" and later lets the hybrid approach know what
it is allowed to republish.

### 4. Listener changes (no new tables)
Today any `scene` event triggers a full sync. That cannot stay: `status.active` changes on every
recall, and during an animation the bridge also updates scene status, so a full sync per event
would be constant. `Hue::Mirror` needs a `scene` branch:
- `add` / `delete` -> full sync (rare).
- `update` carrying only `status` -> set `active` / `last_recalled_at`, broadcast the scene card.
- `update` carrying `actions`, `palette`, `speed`, `auto_dynamic`, or `metadata` -> update the
  row, rebuild its `hue_scene_actions`, broadcast the card.
`Hue::Sync` rebuilds actions for every scene on a full sync.

### 5. Client methods (no tables)
```ruby
create_scene(group_kind, group_id, name:, actions:, palette: nil, speed: nil, auto_dynamic: false)  # POST scene -> id
update_scene(id, attrs)                                                                            # PUT scene/{id}
delete_scene(id)                                                                                   # DELETE scene/{id}
recall_scene(id, action: "active" | "dynamic_palette" | "static", duration_ms: nil)               # PUT scene/{id} recall
```
`actions` is `[{ light_id:, on:, brightness:, xy: | mirek: }]` and the client shapes it for the bridge.
Validation the bridge enforces and we surface rather than duplicate: name 1-32 chars, every target
light must belong to the group, at least one action.

### 6. App-authored scenes (app-owned tables; drafts included)
Everything we author lives in our own tables, published to the bridge from there. The same two
tables are where app-hosted custom scenes live later; a published scene and a custom scene differ
only in whether `hue_scene_id` is set.
```
scenes
  id              integer PK
  name            string
  group_id        string FK hue_groups null      room/zone it targets; null = cross-room (custom, later)
  palette         json null                       same shape as the bridge's
  speed           decimal null
  auto_dynamic    boolean default false
  transition_ms   integer default 400
  hue_scene_id    string FK hue_scenes null       set once published; nil = draft or app-only
  published_at    datetime null
  published_stamp datetime null                   the bridge's last_actions_update at publish time; drift = mirror's is newer
  created_at, updated_at

scene_lights
  id              integer PK
  scene_id        integer FK scenes (cascade)
  light_id        string FK hue_lights (cascade)
  on              boolean
  brightness      decimal(5,2) null
  color_x, color_y decimal null
  mirek           integer null
  unique (scene_id, light_id)
```
The editor edits a `scenes` row directly (autosave per control), so a draft survives reloads and
devices. "Try" PUTs the row's lights to the bulbs. "Save & publish" POSTs/PUTs the bridge scene,
sets `hue_scene_id`, `published_at`, `published_stamp`, and `made_here` on the extension row.
"Capture" creates a row from the room's current mirror state. `custom_scenes`/`custom_scene_states`
from DB_DESIGN.md are superseded by these two tables.

### Stock scene identity
The bridge keeps no gallery (no listable image resource; Hue's library is in its cloud app). But a
stock scene added to several rooms carries the same `metadata.image.rid` and the same palette in
each, so the image id is a stable stock identity: 16 distinct ids across the 28 scenes here. Store
it as `hue_scenes.image_id` and use it to group "Palm Beach, in 3 rooms" as one card with rooms
beneath, and to offer "add to another room" by copying the palette and remapping actions to that
room's lights. Hand-made Hue-app scenes have no image id (none exist here yet).

### Showing a scene's colours
- Card: one dot per light in its scene colour dimmed by its scene brightness (the tiles' tint
  maths), sorted by hue so the row reads as a spectrum; whites as warm/cool tinted dots.
- Card background: the palette as a low-opacity horizontal gradient (the animated mood). No
  palette, flat card.
- Expanded: per-light list rendered with the tile partial via `SceneAction#to_snapshot`.
- Active scene highlighted; Set and Play buttons; "playing" badge.

### 6b. Drafts
Not a separate table: a `scenes` row with `hue_scene_id` nil.

### 7. Activity
Already covers it: `target_kind: "scene"`, actions `scene` (recall), plus new `create`, `update`,
`delete`, `play`, `freeze`. Nothing to add.

### Order inside this part
1. Columns on `hue_scenes` + `hue_scene_actions` + the Mirror scene branch (stops the full-sync storm too).
2. `hue_extensions_scenes` and the Scenes page with Set / Play, favourites, hiding, ordering.
3. Client create/update/delete and the editor with Try, Save, Capture.

## Recommendation and order

1. **Part 1, Approach B.** `hue_scene_actions` + `hue_extensions_scenes` + the Scenes page.
   The page is the quickest visible win and the table is the foundation for everything after.
2. **Capture.** "Save current state as a scene" from a room: one button, writes a custom scene from
   the mirror. No editor yet. Immediately useful.
3. **Editor.** A scene is a room's tiles with the panel controls, but writing to the scene instead
   of the bulb, with "Try" (push to bulbs without saving) and "Save". Reuses the panel component.
4. **Publish (Approach 3).** Push a custom scene to the bridge as a real scene so it recalls
   atomically and works with the switches. Drift detection after that.

## Open questions to decide before step 3

- **Dynamic scenes.** Should ours support a palette and the bridge's animation, or static only?
  Static first; palette is a column later.
- **What "active" means for a cross-room custom scene** once lights drift. Suggest: active if every
  light matches within tolerance, shown as a highlight on the card.
- **Transitions.** Bridge scenes take a `dynamics.duration` on recall. Store a per-scene default.

## The scenes views

### Routes
- `/scenes`: every scene, grouped by room/zone (stock identity collapses "Palm Beach, in 3 rooms"
  into one card with the rooms beneath). Cards as described above; tapping a card goes deeper.
- `/scenes/:id`: one scene drawn on its room's floor. A bridge scene belongs to exactly one room or
  zone, so the room is implied by the scene. `?room=` is only needed later for app-authored scenes
  that span rooms, where it picks which room's floor to draw. (`/scenes/room?id=x&scene_id=x`
  works as a URL too; the nested form just keeps the room out of the query when it is implied.)
- `/rooms/:id/floor`: the same drawing of a room's **live** state. Free once the floor renderer
  exists, and it is the natural home for the layout editor.

### The floor
A dark container with a fixed aspect ratio; each light is an absolutely positioned HTML button at
its stored x/y percentages (chosen over SVG: dragging is then just updating the same percentages
we store, each dot is a real focusable control with a proper tap target, names are plain text,
and the glow is one CSS radial gradient on a pseudo-element). Each dot has:
- a small solid disc in the light's scene colour (grey when off),
- a soft glow: a radial gradient from the colour to transparent, radius and opacity both scaled by
  the scene brightness (roughly radius 12 + 18 * bri/100 units, peak opacity 0.1 + 0.5 * bri/100),
  drawn with `mix-blend-mode: screen` so overlapping glows add like real light (CSS custom
  properties for colour and brightness drive both),
- the light's name beneath in muted ink.
Whites use the warm/cool tint; a light the scene doesn't touch is drawn dim with no glow.
Rendering needs only `House::Light`-shaped values, so it takes a live room, a bridge scene (from
`hue_scene_actions`), or an app scene (from `scene_lights`) with the same code.

### Remembering where the lights are (app-owned)
```
light_placements
  id          integer PK
  group_id    string FK hue_groups (cascade)
  light_id    string FK hue_lights (cascade)
  x           decimal(5,2)   0..100, % of the floor's width
  y           decimal(5,2)   0..100, % of the floor's height
  unique (group_id, light_id)

hue_extensions_groups  (+ column)
  floor_aspect  decimal default 1.0   width / height of the room's floor
```
Per room *and* light, because the same light sits in a room and in a zone and the two floors
differ. Lights without a placement are auto-arranged in a row along the bottom with a "place me"
hint, so the view works before any setup.

### Setting a room up
"Edit floor" on `/rooms/:id/floor`: drag dots (pointer capture on the button; arrow keys nudge),
snapping to a 10-unit grid, each drop saved at once
with `PATCH /rooms/:id/floor` carrying `{ light_id, x, y }`; a handle on the frame sets the aspect.
No separate layout editor page, and no drafts: a placement is a fact the moment it is dropped.

### What it unlocks
- `/scenes/:id` is the scene on the floor; Set / Play buttons there as on the card.
- The scene editor draws the draft on the floor and opens a light's panel when its dot is tapped,
  writing to `scene_lights` instead of the bulb. "Try" pushes it to the real room.
- The live floor doubles as a second everyday view for people who think in rooms, not lists.

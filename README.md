# you can hue better

A small Rails app for the Philips Hue lights in the house. Each light is a tile painted with its real
colour and brightness. Tap a tile to toggle it, drag to dim, pick a colour, or recall a scene for a room.
Everything talks to the bridge over the LAN; nothing goes through the Hue cloud.

## Run it

    bin/rails db:prepare
    bin/rails server

Then open http://localhost:3000. Any phone on the same wifi can use `http://<this-mac>.local:3000`.

The three main views share a Lights / Scenes / Floor switch in their headers.

Scenes live at `/scenes` (cards per room: a dot per light in its scene colour, the palette behind,
Set and Play) and `/scenes/:id`, which draws the scene on the house **floor**: every light the scene
sets in its scene state, every other light greyed out. `/floor` is the one floor for the whole house
(keyed by the bridge's home group), live, with Edit floor to drag lights into place (`light_placements`)
and a shape control. Its chips filter to a room (others greyed) and then preview any of that room's scenes the same
way, without touching the bulbs. Tapping a light outside edit mode opens its panel floating beside it
(the same switch, brightness and colour controls as the rows), and drags on it paint the floor live. Unplaced lights line up along the bottom until dragged.
The floor has a camera (`lib/floor_camera.js`): pinch or ctrl-scroll to zoom up to 6×, drag or scroll to pan,
double-tap to zoom in, buttons for in, out and fit. Labels follow the zoom: room names only when far, lamp
glyphs when nearer, glyph and name when close; the selected lamp always shows both. Lamps carry a glyph for
what the bulb is (lamp, candle, spot, strip) from its Hue archetype. Editing is hidden below 900px wide.

Edit floor can draw a **house outline** and **room nets** (`floor_nets`): click to add points, click the first
point (or press Enter) to close the loop, Escape to abandon. Nets are labels for the floor, not physics: they
name regions, double-tap frames one, and a room can have several. The outline blocks and bounces light like
a wall and darkens the void outside it. A selected net shows draggable points (double-click one to remove it)
and a room picker.

**Paint** (`floor_paints_controller.rb`): a tray of whites, colours, a hue slider, the previewed scene's
palette and recent colours. Pick one, then tap or sweep across lamps, or tap a room's name in a net to
paint the whole room. Lamps repaint locally; Apply sends one command per light and offers Undo.

**Visibility** (`/dev`, `visibility_controller.rb`): per room, hidden; per light, hidden, on floor, and an
icon override. Hidden here is hidden everywhere outside /dev, including counts and the floor. "On floor"
takes a light off the floor plan without hiding it. On a phone the Lights/Scenes/Floor nav is a bottom
tab bar.

Edit floor also adds **walls** and **furniture** (boxes and rounds): drag to move, resize from the corner,
rotate from the top handle or the toolbar's ±15° (or `[` / `]`), Remove or Delete key; saved in
`floor_objects`. The floor is a square grid (a cell is a tenth of the width); drops snap to a tenth of a cell,
fine enough to feel free. **Preview** on the live floor shows any of the room's scenes on the lamps without touching
the bulbs, with a Set button to actually recall it. The light is drawn on a canvas (`lib/floor_light.js`): each light fills what it
can see past the walls, and every wall face it can see bounces light back as a mirrored source clipped
to that face, so the floor brightens next to a wall. Furniture is drawn but does not affect the light.
See `docs/SCENES_PLAN.md` for where this is going.

Two views share the same partials:

- `/` is the everyday view, built for a phone: compact rows, no logs. Rooms collapse (tap the name),
  remembered per device. Arrange reorders rooms and saves the order on the server (`hue_extensions_groups`),
  shared by every device. Rooms that have never been arranged fall in after the placed ones, ordered by
  most lights, then most lights on, then name.
- `/dev` is the developer view: the same rooms plus the activity log, the press log and the listener status.

Names: tap a light's name in its panel, or a room's Rename button in Edit mode. On `/` this sets a
**nickname**, which only this dashboard shows (the bridge's name appears in small text next to it). On
`/dev` it can also **rename** the room or light on the bridge itself, which the Hue app and the switches
then see too; a bulb and the device that owns it are renamed together. Nicknames live in the
`hue_extensions_*` tables.

Bridge connection details come from `config/hue.json` (gitignored):

    {"bridge":"192.168.0.44","username":"<app key>","clientkey":"<client key>"}

or from the environment as `HUE_BRIDGE` and `HUE_APP_KEY`. See `docs/HUE_NOTES.md` for how the
key was obtained, the full light and scene inventory, and API notes. A Postman collection is in `postman/`.

## How it fits together

- `app/services/hue/client.rb` wraps the CLIP v2 API over one persistent TLS connection.
- `app/services/hue/color.rb` converts between hex and the CIE xy colours the bridge uses.
- `app/models/house.rb` and `app/models/house/` are plain Ruby snapshots the dashboard renders, built from the mirror tables.
- `app/models/activity.rb` logs every command sent to the bridge.
- `app/models/hue/` are the `hue_*` mirror tables: a cache of bridge state. `Hue::Sync` rebuilds it, and
  `Hue::Listener` (a thread started by a Puma plugin when the server boots) keeps it fresh from the
  bridge's event stream, logs switch presses, and broadcasts changes to open pages over Turbo.
  If the listener isn't live the dashboard refreshes the mirror from the bridge itself first.
- `app/models/control_binding.rb` and friends describe what each remote button and the dial ring should do.
  `bin/rails hue:import_v1_rules` seeds them from the bridge's legacy rules. Nothing acts on them yet.
- `docs/DB_DESIGN.md` explains the schema and the plan for taking over the remotes.
- `app/controllers/lights_controller.rb` handles a tile's three controls; rooms and scenes have their own.
- A light's tile (`tile_controller.js`): the icon switches it, the name pins it, and a sideways drag
  across the tile dims it with the fill following.
- The pinned light (`lights/_pin`, `pinned_controller.js`, `light_panel_controller.js`): a bar docked at
  the top of the page that stays while the room scrolls, with icon, name, level, a slider and the colour
  swatch. Tap the name or swatch to unfold rename and colour beneath it; swipe the bar sideways to move to
  the next light in that room; × unpins. On a phone the floor pins a tapped lamp the same way instead of
  floating a popover.
- A change made through the app is applied to the mirror and broadcast at once (`HouseBroadcast.changes`),
  so every other open page sees it; the bridge's own event then has nothing new to say. A live update
  aimed at something being dragged or previewed is held back (`lib/busy.js`) and lands on release.
- Any action that touches more than one light (room on/off, scene Set or Play) captures the lights'
  states first (`undo_actions`, kept an hour) and offers Undo in its toast.
- `color_picker_controller.js` and `lib/hue_color.js` are that colour component: a Colour/White switch over
  one circle. Colour is a hue/saturation wheel where every pixel is clamped to the bulb's own gamut; White is
  the same circle as a warm-to-cool range. Dragging previews on the tile and panel, releasing sends xy or a
  colour temperature to the bridge. While something is being dragged the panel is marked busy so a live
  update can't replace it mid-gesture.
- Responses are Turbo Streams, so only the tiles that changed re-render. Pages also subscribe to a
  broadcast stream, so a wall switch or the Hue app changing a light shows up without a reload.
- Set `HUE_LISTENER=0` to start the server without the listener.

## Design previews

`design/` holds self-contained preview pages of the app's visual language (colours, type, view switch,
chips and buttons, a room with rows, the light panel, scene cards, the floor), each with an `@dsCard`
marker. Push them to a claude.ai/design design-system project with `/design-sync` from that folder, so
Claude Design can lay out new screens with this app's real look. `design/README.md` says how to refresh them.

## Tests

    bin/rails test

Tests run against an in-memory fake bridge (`test/support/fake_hue_client.rb`); nothing touches the real one.


## Deploying in Docker (clanker)

One container: Rails + Puma on port 3000, SQLite under `/rails/storage` (a named volume), and the
Hue listener thread started by Puma. Action Cable uses Solid Cable on SQLite, so there is no Redis.

```sh
cp .env.example .env            # HUE_BRIDGE, HUE_APP_KEY (from config/hue.json), RAILS_MASTER_KEY (config/master.key)
docker compose up -d --build    # http://clanker:3344
docker compose logs -f hue      # "Live" in the header means the listener is on the bridge's event stream
```

- Secrets come in as environment variables; `config/hue.json` and `config/master.key` are never copied into the image.
- `HUE_BRIDGE`/`HUE_APP_KEY` are optional. Without them the first visit lands on `/setup`: the app finds
  the bridge through Philips' discovery service (or you type its address), you press the bridge's
  button, and the key is stored in the database (`bridge_pairings`, in the volume). Precedence is
  environment, then the pairing, then `config/hue.json`. `/setup` stays available to pair again.
- The container needs to reach the bridge on the LAN. The default bridge network does; a custom network
  with `internal: true` would not.
- Plain HTTP by default. Behind a proxy that terminates TLS, set `RAILS_FORCE_SSL=1`.
- Keep one container (Puma runs single-process), otherwise there would be two listeners writing the mirror.
- The volume holds the mirror, nicknames, positions, floor objects, nets, visibility, undo and activity.
  Back it up with `docker run --rm -v you-can-hue-better_hue_storage:/s -v "$PWD":/b alpine tar czf /b/hue-storage.tgz -C /s .`
- Migrations run on start (`bin/docker-entrypoint` runs `db:prepare`). The bridge's v1 switch rules are untouched by all of this.


## Licence

AGPL-3.0. Use it, change it, run it at home. If you run a modified copy as a service for other
people, you have to share your changes under the same terms. See `LICENSE`.

# you can hue better

A Rails app for the Philips Hue lights in a house. Every light is a tile painted with its real colour
and brightness, every scene is a card, and the whole house is a floor plan you can light, edit and
paint. It talks to the bridge over the local network only; nothing goes through the Hue cloud.

## Run it

    bin/rails db:prepare
    bin/rails server

Open http://localhost:3000. Any phone on the same network can use `http://<this-mac>.local:3000`.

The first visit without a bridge key lands on `/setup`: the app finds the bridge, you press the
bridge's round button, and the key is stored. A key can also come from the environment
(`HUE_BRIDGE`, `HUE_APP_KEY`) or from `config/hue.json` (gitignored, see `config/hue.example.json`).
The environment wins, then a pairing made on the setup page, then the file.

## What it does

**Lights** (`/`) is the everyday view, built for a phone. Rooms and zones collapse, remembered per
device. A tile's icon switches the light, a sideways drag across it dims, and its name pins it: a bar
docked at the top of the page with a slider and colour swatch that stays while the room scrolls.
Swipe the bar to move to the next light; tap it to unfold rename and the colour wheel, which only
offers colours the bulb can actually make. Edit arranges rooms, and the order is shared by every
device. Names set here are nicknames this app shows; the bridge's name sits beside them.

**Scenes** (`/scenes`) shows each room's scenes as cards with a dot per light and the palette behind,
with Set and Play. A scene's page draws it on the floor plan.

**Floor** (`/floor`) is one plan for the whole house. Lamps glow with their real colour; walls block
and bounce the light, furniture is drawn, and an optional house outline shapes it. Pinch, scroll or
double-tap to zoom, drag to pan. Filter to a room, preview any of its scenes without touching the
bulbs, and Set the one you like. Tap a lamp for its controls. Edit floor (desktop only) places lamps,
walls and furniture, and draws room outlines by clicking around a room and closing the loop. Paint
picks a colour and sweeps it across lamps or whole rooms, then applies it in one go.

**Dev** (`/dev`) is the same Lights view plus the command log, the switch-press log, the listener's
status, renaming on the bridge itself, and a visibility list: hide rooms or lights everywhere outside
`/dev`, take a light off the floor plan, or override its icon.

## How it fits together

The bridge is the source of truth. The app keeps a mirror of it, and the mirror only ever holds what
the bridge has said. The one guess is in the browser tab that pressed: it shows the press straight
away, and the bridge's answer replaces it a moment later.

- **Talking to the bridge** (`app/services/hue/api/`): `Hue::Api::Client` exposes one resource class per
  bridge resource (`client.lights.update`, `client.scenes.recall`, …) over a persistent connection.
  `Hue::Api::Payloads` read every field of the bridge's JSON, and `Hue::Api::LightChange` writes the one
  thing the app sends most: what a light should do. `Hue::Api::Limits` holds the bridge's ranges.
  `Hue::Pairing` finds the bridge and gets a key. `Hue::Color` converts between hex and CIE xy.
- **The mirror** (`app/models/hue/`, tables `hue_*`; `app/services/hue/mirror/`): a cache of bridge
  state. `Hue::Mirror::Sync` rebuilds it in steps, one per table. `Hue::Mirror::Listener`, a thread a
  Puma plugin starts with the server, applies the bridge's event stream through `Hue::Mirror` (one
  applier per resource type), logs switch presses, and reconnects with backoff. Set `HUE_LISTENER=0` to
  start the server without it. Nothing under `Hue` knows about the pages.
- **App-owned data**: `hue_extensions_*` tables share an id with the mirror row they extend (nicknames,
  room order, visibility, icons). Floor placements, objects and outlines, the command log,
  remote-control bindings and the stored pairing have their own tables. `docs/DB_DESIGN.md` explains the
  schema.
- **What the pages render** (`app/models/house.rb`, `app/models/house/`): immutable snapshots built from
  the mirror, with hidden rooms and lights left out outside `/dev`. `House::Glow` is the one formula for
  how a light's colour and brightness tint a tile, a scene dot and a lamp on the floor.
- **The floor** (`app/models/floor.rb`, `app/models/floor/`): the plan, its coordinates and geometry, and
  its three tables (`Floor::Placement`, `Floor::Item` for walls and furniture, `Floor::Net` for outlines).
- **Commands** (`app/services/house_commands/`): everything that changes the house is one command.
  `HouseCommands::Command` runs it one of two ways, and the controller says which with a block that
  builds it (`HueCalls`):
  - `async_hue_call` (lights, rooms, scenes, paint) answers 202 straight away. `call_later` claims the
    command's lights in `Hue::Locks`, logs the press as pending, and `HouseCommands::Dispatch` sends it
    on its own thread. `HouseCommands::Settlement` settles the log row (ok, not responding, or the
    bridge's error), sends any toast to the tab that pressed, broadcasts the truth, then frees the
    lights with a `settle` message. Nothing is retried.
  - `direct_hue_call` (renames) waits for the bridge and the action renders the result, as before.

  A press on a light that is still being changed is refused, never queued: the controller answers 409
  with the light's real state and a "being changed from another device" toast. `Hue::CallTimings`
  keeps the P95 of recent calls per kind of command; the 202 carries it as `Check-In-After`, the time
  after which a tab that missed `settle` asks `GET /locks`. Actions that never talk to the bridge stay
  plain Rails. `INSTANT_COMMANDS_PLAN.md` is the plan this was built from.
- **Live pages**: every change, from this app, the Hue app or a wall switch, reaches open pages as
  Turbo Streams. `HouseBroadcast::Streams` builds each update once, for both a controller's reply and
  the broadcast, and `HouseBroadcast::Targets` names the elements they replace. An update aimed at something under the pointer waits until it is released
  (`app/javascript/lib/busy.js`). Each page also has its own stream, so a toast about a press reaches
  only the tab that made it. While a press holds a light, the listener skips that light's bridge
  events, so a late echo of the previous press can't flicker the tile.
- **Front end**: Stimulus controllers in `app/javascript/controllers/`, with shared maths and helpers in
  `app/javascript/lib/` (colour, the floor's camera, geometry and light). `lib/requests.js` is the only
  place that calls `fetch`. Presses use the same two names as the controllers: `asyncHueCall` and
  `directHueCall` in `lib/hue_calls.js`, and forms built with `async_hue_form_with`,
  `async_hue_button_to` or `direct_hue_form_with` (the `async-hue-call` and `direct-hue-call`
  controllers). `lib/light_intents.js` tracks which lights are pending in this tab: they pulse, refuse
  taps and drags with a "still changing" toast, and take the truth in one go when they settle. Tiles,
  pins and floor lamps carry their lit and off looks from Ruby, so the guess looks exactly like the
  real thing. Colours and limits the
  browser shares with Ruby arrive from Ruby in the page head (`lib/light_constants.js`). The floor's controller wires
  the page to the classes in `lib/floor/`, one per job. Stylesheets are one file per part of the page,
  with shared values in `tokens.css`. Every piece of visible text is in `config/locales/en.yml`.
- **Remote controls**: `ControlBinding` and friends describe what each switch button and the dial ring
  should do, seeded by `bin/rails hue:import_v1_rules` from the bridge's own rules. Nothing acts on them
  yet: the bridge's rules still drive the switches.

`docs/HUE_NOTES.md` covers the bridge API as this app uses it. `docs/SCENES_PLAN.md` is the plan the
scenes and floor were built from.

## Tests

    bin/rails test

The tests run the real client against a fake bridge connection (`test/support/fake_bridge.rb`), so
nothing touches the real bridge. `bin/ci` runs the style checker, the security audits and the tests.

## Design previews

`design/` holds preview pages of the app's look for a claude.ai/design project. See `design/README.md`.

## Deploying in Docker

One container: Rails and Puma on port 3000, SQLite in a named volume, and the listener thread. Live
updates use Solid Cable on SQLite, so there is no Redis.

```sh
cp .env.example .env            # RAILS_MASTER_KEY; HUE_BRIDGE and HUE_APP_KEY are optional
docker compose up -d --build    # http://<host>:3344
docker compose logs -f hue      # "Live" in the page header means the listener is on the event stream
```

- Secrets come in as environment variables; `config/hue.json` and `config/master.key` never go in the image.
- Without a bridge key the first visit lands on `/setup`, and the pairing is stored in the volume.
- The container must reach the bridge on the local network; Docker's default network does.
- Plain HTTP by default. Behind a proxy that terminates TLS, set `RAILS_FORCE_SSL=1`.
- Run one container only, or two listeners would write the mirror.
- Migrations run on start. Back up the volume with
  `docker run --rm -v you-can-hue-better_hue_storage:/storage -v "$PWD":/backup alpine tar czf /backup/hue-storage.tgz -C /storage .`

## Licence

AGPL-3.0. Use it, change it, run it at home. If you run a modified copy as a service for other
people, you have to share your changes under the same terms. See `LICENSE`.

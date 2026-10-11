# Lights page: moving to the G1 design

Written 2026-10-11. **Built so far:** steps 1–3 (tile switches, the bottom light sheet, the room
card and body split with the new card design). Rooms are still stacked until step 4. The design is the "F1: all rooms panel" page of the
design canvas (G1) plus E3 for an open light, and the clickable prototype shows how it behaves.

## Where we're going

One room at a time, phone first:

- **Room tabs** along the top, one per room, with a dot that glows when the room has a light on.
  A round **all-rooms button** sits at the end of the tab row.
- **Room card** under the tabs: name, summary ("7 of 8 on · 73%"), a dot per light in its colour,
  a room switch and a wide brightness bar. Swipe the card left or right to change room; the tabs
  follow, and dots under the card show which room you're on.
- **Scenes** row, then the **light tiles** for that room only.
- **Tiles**: a switch in the light's colour replaces the round dot, so a light can be turned on or
  off without opening it. Drag across a tile to dim it (as now); tap the rest of it to open it.
- **Open light (E3)**: the light's controls dock at the bottom, above the tab bar, without dimming
  the room: switch, name (tap to rename), close ˅, a wide brightness bar in the light's colour,
  Colour / White, then the colour wheel (or the white range). Tapping another tile switches light.
- **All rooms (G1)**: a bottom sheet with a scrolling row per room (name, summary, dots, brightness
  bar, its own switch). Tap a row to go to that room. Tap outside, ˅ or drag down to close.
- **Gone**: the "All off" button, collapsing rooms, and the long list of every room on one page.

Both sheets share one frame: grab handle, ˅ close button, sitting above the tab bar. Only the
all-rooms sheet dims the page behind it.

## What exists today and what it becomes

| Today | Becomes |
|---|---|
| `dashboard/_lights`: every room stacked, header with summary, status, Edit | Tabs + pager + the active room's body; Edit moves into the all-rooms sheet |
| `rooms/_room` (head + scenes + tiles), replaced whole by `Streams.room` | Split in two: `rooms/_card` (in the pager) and `rooms/_body` (scenes + tiles) |
| `rooms/_head`: title button that collapses, power icon button, range | `rooms/_card`: no collapse, a switch styled from the same `room[on]` form, wide bar |
| `room_controller.js` (collapse, `rooms:collapsed` in localStorage) | Deleted |
| `rooms_controller.js` edit mode, move up / down on the page | Same actions, but on rows in the all-rooms sheet |
| `lights/_light`: `.tile__icon` dot with the light's icon is the toggle | `.tile__switch` in `--hue`; no icon |
| `lights/_pin` + `pinned_controller` sticky dock at the top, expands to `_panel` | `lights/_sheet`: the E3 dock at the bottom, always showing `_panel`'s controls |
| `light_panel_controller.js` pins into `#light_dock` | Same job, opens the bottom sheet, closes it when the room changes |

The floor page (`floors/_floor`) also uses the pin dock, and keeps it.

## Live updates

Everything still comes from `HouseBroadcast`; the page renders every room up front (cards in the
pager, bodies hidden except the active one), so the existing targets keep working.

- New targets in `HouseBroadcast::Targets`: `room_card(room)`, `room_body(room)`, `room_tab(room)`,
  `room_row(room)` (the all-rooms sheet). `light_tile`, `light_panel` stay; `light_pin` stays while
  the floor uses it, and the new `light_sheet(light)` joins it.
- `Streams.room_changes`: where it replaces `room_head` today, replace `room_card`, `room_tab` and
  `room_row` (all three show the room's on count, level and light dots).
- `Streams.room` (used by `HouseBroadcast.rooms` and the custom scene move) replaces `room_card`
  and `room_body` instead of the whole `room_N` section.
- `Streams.light_details`: add the `lights/sheet` replace next to the panel.
- `light_preview.js` already updates anything with `data-light-id`, so the switch colour, the
  tile fill and the sheet follow a drag before the bridge answers. The light dots on the card and
  rows need `data-light-id` too, so they preview the same way.

## Steps

Each step ships on its own and leaves the page working.

1. **Tile switch.** In `lights/_light`, swap `.tile__icon` for a switch (`role="switch"`,
   `aria-checked`, still `tile#toggle`). CSS in `tiles.css` from the canvas: track in `--hue` when
   on, `--line` when off. Update `tiles_test.rb` / `live_update_test.rb` selectors.
2. **Light sheet at the bottom (E3).** New `lights/_sheet` (head with switch, name, close; wide
   brightness range in `--hue`; the `_panel` picker). `#light_dock` becomes a fixed bottom sheet above
   `.views`, with `padding-bottom` on the page while it's open. `light_panel_controller` loads it
   from a new `html/lights/:id/sheet` action (copy of `pin`). Keep `pinned#swipe` to move between
   lights. Tests: `html/lights_controller_test.rb`, `pinned_light_test.rb`.
3. **Split the room partial.** `rooms/_card` + `rooms/_body`, new targets, stream changes above.
   Still rendered stacked at this point, so it can be checked on its own. Update
   `rooms_controller_test.rb` and `live_update_test.rb` for the new targets.
4. **Tabs and pager.** `dashboard/_lights` renders the tab row, a scroll-snap pager of every
   `_card`, page dots, and every `_body` with only the active one shown. New
   `room_pager_controller.js`: watches the pager's scroll to set the active room, moves the tab and
   shows the body; tapping a tab scrolls the pager; remembers the room in localStorage
   (`rooms:current`) and falls back to the first room. Closes the light sheet when the room changes.
   Delete `room_controller.js` and the collapse CSS.
5. **All-rooms sheet (G1).** `dashboard/_all_rooms` in a `<dialog>`, a `rooms/_row` per room with
   its own `room[on]` switch form. `all_rooms_controller.js`: open from the tab-row button, close on
   backdrop / ˅ / Escape / drag down, tap a row to call the pager's `goTo`. Move the Edit button
   and `rooms#moveUp` / `moveDown` / rename onto the rows; `saveOrder` reads the rows' order and
   reorders the tabs, cards and bodies to match.
6. **Tidy up.** Remove the "All off" leftovers, the old `.room__head` CSS, `--picker-size` tweaks
   for the sheet, unused locale keys (`rooms.head.*`). Shared sheet CSS (handle, close, frame) in one
   file. Update the README's description of the dashboard.

Every step: `bin/rails test`, `bin/rubocop`, `bin/brakeman`, then a look on a phone.

## Decided (2026-10-11)

1. **Wide screens**: the same layout, centred at a phone-ish width.
2. **Light icons**: dropped from the tiles for now (the floor still draws them).
3. **Floor page**: left as it is, with the top pin dock. Step 2 only changes the dashboard, and
   `_pin`, `pinned_controller` and `light_pin` stay for the floor.
4. **`/dev`**: gets the new layout too (it renders the same `dashboard/_lights`).
5. **Scenes row**: stays on the main screen, under the room card.

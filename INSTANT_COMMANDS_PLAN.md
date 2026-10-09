# Instant commands

A press on a light, room, scene or floor paint answers straight away. The bridge call runs on its
own thread, and the page finds out how it went when the bridge answers. This plan splits the work
into chunks that can be reviewed on their own. A chunk is reviewed, any comments are addressed,
then it is committed, pushed and ticked off here before the next chunk starts.

The decks behind it:

- [Instant Light Commands](https://claude.ai/artifact/Wb5ajWXFGWKF5eAf5iaySR): what the person sees.
- [Instant Commands Architecture](https://claude.ai/artifact/SDCSjR2k3PBmVFsKJLEGeB): how the code fits together, the patterns it builds on, examples, pros and cons.

The rules from `REFACTOR_PLAN.md` still apply to every file touched here.

Status: `[ ]` not started, `[~]` done and waiting for review, `[x]` reviewed, committed and pushed, `[-]` skipped.

## Decisions

1. **Only the person who pressed sees a guess.** The pressing tab draws the press straight away.
   The server never predicts: its mirror only holds what the bridge confirmed, and every other
   screen changes when the bridge has answered.
2. **Pending means denied, never held.** While a light is pending, taps on it send nothing and
   show a "still changing" toast. A drag released on it snaps its preview back with the same
   toast. Nothing is saved to send later. A room press is denied if any of its lights is pending.
3. **Locks bounce, they never queue.** `Hue::Locks` claims all of a command's lights or none.
   A press on a locked light gets a 409 straight away, so there is no ordering to get wrong.
4. **The second device loses.** The 409 carries the lights' real state as Turbo streams plus a
   "being changed from another device" toast. The tile snaps back and the reason appears together.
5. **A failure snaps back with a toast, and is never retried.** The thread re-reads the bridge
   and broadcasts the truth to every tab, which is the undo. The person can press again.
6. **"Not responding" keeps the change.** The bridge applies it when the bulb gets power back,
   so the pulse stops and a warning toast shows.
7. **Toasts go only to the tab that pressed.** Each page load gets its own signed Turbo stream
   next to the shared house stream. The truth still goes to everyone.
8. **The controller says which reply it gives.** `async_hue_call` answers 202 straight away.
   `direct_hue_call` waits for the bridge and renders as today. Actions that never talk to the
   bridge stay plain Rails.
9. **The browser says it the same way.** The JavaScript helpers, view helpers and Stimulus
   controllers use the same two names, so a search for `hue_call` or `hueCall` lists both sides.
10. **Every press sends an absolute state.** `on=true` or `brightness=40`, never `toggle`.
11. **The safety net is the P95 of real call times.** `Hue::CallTimings` keeps the last 100
    calls per kind (light, room, scene, paint). Before 20 samples it is 1000 ms; it is never
    under 250 ms or over the HTTP timeout. When it runs out the browser asks `GET /locks`
    whether the lights are free. Asking early costs one tiny request.
12. **The listener skips events for locked lights.** The bridge's events can lag by up to a
    second, and a late one from the previous press would flicker the tile.
13. **A room's brightness is the browser's estimate** from its lights until the truth arrives.
14. **Scenes and paint show the pulse, not a guess.** The browser doesn't know a scene's colours,
    and the floor already previews paint strokes. Their lights pulse until the truth arrives.
15. **One process, so no Redis.** Locks and timings live in memory. `Hue::Locks` is the only
    class that would move to shared storage if the app ever runs two processes.
16. **Later, not now: a lock ping.** Broadcast "claimed" and "free" to every screen so other
    devices dim a busy tile before anyone presses it. The "free" half already exists as `settle`.

## Names on both sides

| Where | Answers straight away | Waits for the bridge |
|---|---|---|
| Controller | `async_hue_call { command }` | `direct_hue_call { command }` |
| Command | `call_later` returns `Accepted` or `Busy` | `call_now` returns the result or `Busy` |
| View helper | `async_hue_form_with`, `async_hue_button_to` | `direct_hue_form_with` |
| Stimulus controller | `async-hue-call` | `direct-hue-call` |
| JavaScript | `asyncHueCall(url, fields, lightIds)` | `directHueCall(url, fields)` |

The view helpers wrap `form_with` and `button_to`, add the matching Stimulus controller, and for
async forms render the light ids the press will make pending:

```erb
<%= async_hue_button_to scene.name, activate_scene_path(scene.id), light_ids: scene.light_ids %>
```

## How a press flows

1. The browser checks the lights are free. If not, it shows the "still changing" toast and stops.
2. It draws the guess (lights and rooms only), marks the lights pending and starts the pulse.
3. `asyncHueCall` sends the absolute state with the tab's id in a header.
4. The controller's `async_hue_call` block builds the command in the request.
5. `call_later` claims the lights, logs a pending activity row, and hands the bridge call to
   `HouseCommands::Dispatch`. The reply is 202 with `Check-In-After`, or 409 with the truth.
6. The thread sends to the bridge, times the call, and `HouseCommands::Settlement` picks one of
   three endings: ok, not responding, or failed.
7. The thread reads the lights back, broadcasts the truth to every tab, sends any toast to the
   pressing tab, settles the activity row, releases the claim and broadcasts `settle`.
8. Every tab stops the pulse for those lights. If `settle` never arrives, the check-in asks
   `GET /locks` once the P95 has passed.

## Chunk 1: One way the browser talks to the server

A pure refactor before anything async lands on top of it. If a person submits a form, Turbo
sends it. If code sends it, `lib/requests.js` sends it: it is the only file that calls `fetch`,
and it sets the CSRF token and the Accept header in one place.

- [x] `app/javascript/lib/requests.js` (`request`, `post`, `patch`, `destroy`, `getHtml`, `getJson`, `renderStreams`, `ACCEPT`; field arrays become repeated fields)
- [x] `app/javascript/lib/floor/net_editor.js` (`post`, `patch`, `destroy`)
- [x] `app/javascript/lib/floor/layout_editor.js` (`post`, `patch`, `destroy`)
- [x] `app/javascript/lib/floor/paint_brush.js` (`post`, `renderStreams`)
- [x] `app/javascript/lib/floor/scene_preview.js` (`getJson`)
- [x] `app/javascript/lib/floor/lamp_panel.js` (`getHtml`)
- [x] `app/javascript/controllers/light_panel_controller.js` (`getHtml`)
- [x] `app/javascript/controllers/rooms_controller.js` (`patch` with the room ids as a field)
- [x] `app/javascript/controllers/floor_controller.js` (`csrfHeaders` removed)

Live check:

1. Floor: add an object, move it, resize it, delete it. Draw a net, move a point, delete it.
2. Floor: move a lamp and change the aspect, then reload: both kept.
3. Floor: preview a scene from a room chip, then paint the Kitchen lamp and apply.
4. Dashboard: open a light panel and pin it. Reorder two rooms, reload, put them back.
5. Tap and drag the Kitchen lamp tile, and pick a colour: all work as before.

## Chunk 2: Locks and call timings

The two in-memory pieces everything else stands on. Nothing calls them yet.

- [x] `app/services/hue/locks.rb` (new: `claim`, `release`, `locked?`, `locked_among`, a `Set` behind a `Mutex`)
- [x] `app/services/hue/locks/claim.rb` (new: `Data` holding the claimed light ids)
- [x] `app/services/hue/call_timings.rb` (new: `measure`, `record`, `p95_milliseconds` per kind; the ceiling is the bridge connection's open plus read timeouts, 8000 ms)
- [x] `test/services/hue/locks_test.rb` (new: claim, bounce, all or none, release, empty claim, racing threads)
- [x] `test/services/hue/call_timings_test.rb` (new: default, floor, ceiling, rolling window)

Live check:

1. `bin/rails console`, then `claim = Hue::Locks.claim(%w[a b])` returns a claim.
2. `Hue::Locks.claim(%w[b c])` returns nil, and `Hue::Locks.locked?("c")` is false.
3. `Hue::Locks.release(claim)`, then `Hue::Locks.claim(%w[b c])` returns a claim.

## Chunk 3: Pending and settled activity rows

The log shows a press as pending first, then what happened.

- [x] `app/models/activity.rb` (`PENDING`, `INTERRUPTED`, `pending` scope, `pending?`, `settle!`, `interrupt_pending!`)
- [x] `app/services/activity_recorder.rb` (adds `pending`, keeps `record` for `call_now`)
- [x] `app/views/activities/_activity.html.erb` (the result span is `result`, not `err`, since pending isn't an error)
- [x] `app/helpers/dashboard_helper.rb` (`pending` class)
- [x] `app/assets/stylesheets/dev.css` (pending shows soft and italic)
- [x] `lib/puma/plugin/hue_listener.rb` (`LeftoverActivity` marks leftover pending rows as cut short by a restart, server boot only)
- [-] `config/locales/en.yml` (results are stored text constants on `Activity`, like `OK` and `UNREACHABLE`)
- [x] `test/models/activity_test.rb` (new)
- [x] `test/services/activity_recorder_test.rb`

The tidy-up runs from the Puma plugin, not an initializer, so opening a console while the server
runs never marks a live press as interrupted.

Live check:

1. In the console, `ActivityRecorder.pending(...)` creates a row that shows as pending in the log.
2. `row.settle!(Activity::OK)` and the log shows it as ok.
3. Leave a pending row, restart the server, and it shows as cut short by a restart.

## Chunk 4: Running a command two ways, on single lights

The server side end to end, switched on for `lights#update` only. Other actions keep calling
`.call` until chunk 7. The browser is unchanged until chunk 6: the tile updates when the truth
broadcast arrives, about 100 to 600 ms later, instead of from the reply.

- [ ] `app/services/house_commands/command.rb` (`call_now`, `call_later`, `light_ids` defaulting to empty, `kind`)
- [ ] `app/services/house_commands/accepted.rb` (new: `Data` with light ids and the check-in time)
- [ ] `app/services/house_commands/busy.rb` (new: `Data` with light ids)
- [ ] `app/services/house_commands/not_instant.rb` (new: raised when `call_later` has no lights)
- [ ] `app/services/house_commands/dispatch.rb` (new: thread, executor wrap, timing, ensure release and `settle`)
- [ ] `app/services/house_commands/settlement.rb` (new: the three endings)
- [ ] `app/services/house_commands/light_update.rb` (`light_ids`, `kind`)
- [ ] `app/services/house_broadcast.rb` (`settle`, `toast_to_tab`)
- [ ] `app/services/house_broadcast/streams.rb` (settle and tab toast streams)
- [ ] `app/controllers/concerns/hue_calls.rb` (new: `async_hue_call`, `direct_hue_call`, `LightsBusy`, 202 and 409 replies)
- [ ] `app/controllers/concerns/toast_streams.rb` (toast messages shared with `Settlement`)
- [ ] `app/controllers/lights_controller.rb` (`async_hue_call`)
- [ ] `config/environments/test.rb` (`Dispatch` runs inline)
- [ ] `config/locales/en.yml` (another device, still changing)
- [ ] `test/services/house_commands/command_test.rb` (new: both modes, busy, release on error)
- [ ] `test/services/house_commands/light_update_test.rb`
- [ ] `test/services/house_commands/settlement_test.rb` (new: the three endings)
- [ ] `test/controllers/lights_controller_test.rb` (202, 409 with the truth)

Live check:

1. `curl -i -X PATCH localhost:3344/lights/<kitchen lamp> -d 'light[on]=true'` with a CSRF
   token from the page: 202 with `Check-In-After`, and the lamp turns on.
2. Watch the dashboard in a second tab: the tile turns on when the bridge answers.
3. Send two PATCHes back to back: the second gets a 409.
4. Turn the Kitchen lamp off at the wall and press it: the tile settles, a warning toast shows,
   and the log says not responding. Turn it back on at the wall.
5. `Hue::Locks.locked?(<kitchen lamp>)` is false after each step.

## Chunk 5: The listener skips locked lights

- [ ] `app/services/hue/mirror/listener/batch_handler.rb` (drops light and grouped light events for locked lights)
- [ ] `app/services/hue/mirror/listener/locked_echo.rb` (new: maps a resource to its light ids)
- [ ] `test/services/hue/mirror/listener_test.rb` (locked lights skipped)

Live check:

1. Turn the Kitchen lamp on, off and on as fast as the bounce allows, with a second tab open.
2. Neither tab flickers back to an earlier state.
3. A wall switch press on another room still updates both tabs straight away.

## Chunk 6: The browser side, on single lights

The pressing tab draws the guess, pulses, denies presses while pending, and speaks the same two
names as the controllers.

- [ ] `app/javascript/lib/hue_calls.js` (new: `asyncHueCall`, `directHueCall`, tab id header, 202, 409 and 200 handling)
- [ ] `app/javascript/lib/light_intents.js` (new, replaces `lib/busy.js`: free or pending per light, pulse, bounce toast, check-in timer)
- [ ] `app/javascript/lib/busy.js` (removed)
- [ ] `app/javascript/lib/stream_actions.js` (new: the `settle` Turbo stream action)
- [ ] `app/javascript/lib/requests.js` (sends the tab id header)
- [ ] `app/javascript/application.js` (registers the stream actions)
- [ ] `app/javascript/controllers/async_hue_call_controller.js` (new: async forms)
- [ ] `app/javascript/controllers/direct_hue_call_controller.js` (new: direct forms)
- [ ] `app/javascript/controllers/tile_controller.js` (`asyncHueCall`, sends `on` or `off`, denies drags while pending)
- [ ] `app/javascript/controllers/color_picker_controller.js` (`asyncHueCall`, snaps back while pending)
- [ ] `app/javascript/controllers/light_controller.js` (panel and pin forms through `async-hue-call`)
- [ ] `app/javascript/controllers/toast_controller.js` (bounce toasts)
- [ ] `app/helpers/hue_calls_helper.rb` (new: `async_hue_form_with`, `async_hue_button_to`, `direct_hue_form_with`)
- [ ] `app/views/layouts/application.html.erb` (tab id meta and the tab's own `turbo_stream_from`)
- [ ] `app/views/lights/_light.html.erb`, `_pin.html.erb`, `_panel.html.erb` (async helpers, `on` or `off` not `toggle`)
- [ ] `app/services/house_commands/light_update.rb` (`TOGGLE` removed)
- [ ] `app/controllers/locks_controller.rb` (new: `GET /locks?light_ids=`)
- [ ] `config/routes.rb` (`/locks`)
- [ ] `app/assets/stylesheets/tiles.css`, `light_panel.css`, `pinned_light.css` (soft pulse, still for reduced motion)
- [ ] `test/controllers/locks_controller_test.rb` (new)
- [ ] `test/controllers/tiles_test.rb` (on or off, never toggle)
- [ ] `test/helpers/hue_calls_helper_test.rb` (new: the controller and light ids the helpers render)

Live check:

1. Tap the Kitchen lamp: the tile changes at once and pulses until the bridge answers.
2. Tap it twice quickly: the second tap shows "still changing" and sends nothing (network tab).
3. Drag its brightness while it is pending: the preview snaps back with the same toast.
4. Two tabs: tap in one, then in the other within half a second. The second gets the "another
   device" toast and the truth. Only the first tab sees any guess.
5. Turn the lamp off at the wall and press it: the warning toast shows only in the pressing tab.
6. In the browser console, run `Turbo.StreamActions.settle = () => {}` so `settle` is ignored, then press: the pulse still stops after the check-in. Reload to undo.

## Chunk 7: Rooms, scenes, paint and renames

Everything else that talks to the bridge moves onto the two helpers.

- [ ] `app/services/house_commands/room_switch.rb` (`light_ids`, `kind`)
- [ ] `app/services/house_commands/scene_recall.rb` (`light_ids`, `kind`)
- [ ] `app/services/house_commands/paint.rb` (`light_ids`, `kind`)
- [ ] `app/controllers/rooms_controller.rb` (`async_hue_call`)
- [ ] `app/controllers/scenes_controller.rb` (`async_hue_call` for `activate` and `play`)
- [ ] `app/controllers/floor_paints_controller.rb` (`async_hue_call`)
- [ ] `app/controllers/light_names_controller.rb` (`direct_hue_call`)
- [ ] `app/controllers/room_names_controller.rb` (`direct_hue_call`)
- [ ] `app/views/rooms/_head.html.erb` (`async_hue_form_with` with the room's light ids)
- [ ] `app/views/rooms/_room.html.erb`, `app/views/scenes/_card.html.erb`, `app/views/scenes/show.html.erb` (`async_hue_button_to`)
- [ ] `app/views/shared/_editor.html.erb` (`direct_hue_form_with`)
- [ ] `app/javascript/lib/floor/paint_brush.js` (`asyncHueCall`)
- [ ] `app/javascript/lib/light_preview.js` (room guess: each light on or off, brightness estimate)
- [ ] `app/controllers/concerns/toast_streams.rb` (`result_toast` removed if nothing uses it)
- [ ] `test/controllers/rooms_controller_test.rb`, `scenes_controller_test.rb`, `floor_paints_controller_test.rb`, `names_controller_test.rb`

The browser code has no automated tests today (there is no system test setup), so chunks 6 and 7 lean on their live checks.

Live check:

1. Turn the Mud Pit off, then on as soon as the pulse stops: both feel instant.
2. Tap the Mud Pit while it is pending: "still changing", nothing sent.
3. Laptop turns the Mud Pit off; phone presses one of its lights at once: phone gets the
   "another device" toast and keeps showing the truth.
4. Set a scene from a room chip and from the scenes page: its lights pulse, then show the scene.
5. Play a dynamic scene: the animation starts when the bridge answers.
6. Paint two lights on the floor and apply: they pulse, then show the colours.
7. Rename the Kitchen lamp and a room: the editor waits and closes as today.
8. Check the log shows pending then ok for each press, and the Kitchen lamp and Mud Pit are
   put back as they were.

## Chunk 8: Docs

- [ ] `README.md` (how a press works now, `async_hue_call` and `direct_hue_call`, the browser names)
- [ ] `DB_DESIGN.md` (activity result values: pending, ok, not responding, error, cut short)
- [ ] `INSTANT_COMMANDS_PLAN.md` (this file: everything ticked)

# API and HTML split

Every action that changes something becomes a JSON API at the paths it uses today. Everything that
renders HTML, whole pages and the fragments the browser loads into them, moves into an `Html::`
namespace with the same controller names. The pages learn what is true only from broadcasts: Turbo
Streams arrive over the house stream and each tab's own stream, never in a reply to a request.

This plan splits the work into chunks that can be reviewed on their own. A chunk is reviewed, any
comments are addressed, then it is committed, pushed and ticked off here before the next chunk
starts. The rules from `REFACTOR_PLAN.md` still apply to every file touched here.

Status: `[ ]` not started, `[~]` done and waiting for review, `[x]` reviewed, committed and pushed, `[-]` skipped.

## Decisions to confirm before chunk 1

1. **Decided: where the `Html::` endpoints live in the URL.**
   Recommended: pages keep their URLs (`/`, `/dev`, `/floor`, `/scenes`, `/scenes/:id`, `/setup`)
   so bookmarks keep working, and fragments get an `/html` prefix (`/html/lights/:id/panel`,
   `/html/custom_scenes/new`). Every `Html::` controller is in the namespace in code either way.
   The alternative is `/html` in front of everything, pages included.
2. **Decided: the setup page stays a plain HTML form** that redirects, as
   `Html::SetupController#show` and `#create`, because it runs before there is a bridge and the
   page has nothing to update live. It is the one form post that stays HTML.
3. **Decided: `GET /custom_scenes/:id` stays JSON only.** The HTML page, which only showed the
   scene's name, is removed.
4. **Decided: no-JavaScript fallbacks go.** Every change is sent by the page's JavaScript as JSON.
   The `format.html` redirects that let forms work without JavaScript are removed.

Nothing on screen changes in any chunk: the pages look and behave as they do now. Only the
addresses the browser fetches behind the scenes and the shape of the replies change.

## The conventions

### Controllers

- `ApplicationController` keeps what both sides share: requiring a bridge, CSRF, the browser check.
- `ApiController < ApplicationController`: JSON in, JSON out, nothing else. It turns errors into
  JSON in one place (`JsonErrors`).
- `Html::ApplicationController < ApplicationController`: renders pages and fragments, nothing else.
  It turns a bridge that can't be reached into the "can't reach the bridge" page, as the dashboard
  does today.
- A resource that has both keeps the same name on each side: `LightsController#update` (JSON) and
  `Html::LightsController#panel` and `#pin` (HTML).

### Replies

| Situation | Status | Body |
|---|---|---|
| A press is accepted | 202 | `{ "light_ids": [...], "check_in_ms": 180 }` |
| A direct change is done | 200 | the resource as JSON |
| A record is created | 201 | the record as JSON |
| A record is deleted, or a change has nothing to return | 204 | none |
| The lights are being changed from another device | 409 | `{ "error": "...", "light_ids": [...] }` |
| A record doesn't save | 422 | `{ "error": "...", "errors": { "name": ["can't be blank"] } }` |
| The bridge refuses or can't be reached | 502 | `{ "error": "..." }` |
| Not found | 404 | `{ "error": "..." }` |
| No bridge set up yet | 503 | `{ "error": "..." }` |

### The browser

- `lib/requests.js` gains `sendJson` and `readJson`: JSON bodies, the CSRF and tab headers, and
  errors read from the reply in one place.
- `asyncHueCall` and `directHueCall` send JSON. A 409 puts the tiles back from the copy saved
  before the guess (`snapshotLight`) and shows the error as a toast from `lib/toasts.js`. Any other
  error shows its toast the same way.
- Forms are submitted by Stimulus controllers as JSON, never by Turbo: `async-hue-call`,
  `direct-hue-call`, and a small `json-form` controller for edits that don't touch the bridge
  (visibility, nicknames, custom scene names). Validation errors are written into the form's error
  element by that controller.
- Fragments are loaded with `getHtml` from `Html::` endpoints, as the light panel is today.

## Chunk 1: Pages

The `Html::` base controller and the pages moved into it, without changing their URLs.
`ApiController`, `JsonErrors` and the JSON request helpers arrive in chunk 3, where they are first
used, so nothing ships unused.

- [x] `app/controllers/html/application_controller.rb` (new: the base for everything that renders HTML)
- [x] `app/controllers/html/dashboard_controller.rb` (moved from `DashboardController`)
- [x] `app/controllers/html/floors_controller.rb` (`show`, moved from `FloorsController`, which keeps `update`)
- [x] `app/controllers/html/scenes_controller.rb` (`index`, `show`, moved from `ScenesController`, which keeps `floor_state`, `activate`, `play`)
- [x] `app/controllers/html/setup_controller.rb` (moved from `SetupController`, decision 2)
- [x] `app/views/html/dashboard/`, `html/floors/`, `html/scenes/`, `html/setup/` (the page templates move; shared partials stay where the broadcasts render them)
- [x] `config/locales/en.yml` (the pages' keys move under `html:` with their templates)
- [x] `config/routes.rb` (`scope module: :html` for the pages, URLs unchanged; the floor's `PATCH` and the scenes' members stay outside it)
- [x] `config/environments/test.rb` (a missing translation fails the test instead of showing a placeholder)
- [x] `test/controllers/html/dashboard_controller_test.rb`, `setup_controller_test.rb` (moved; the floor and scene tests stay together until their API chunks)

Live check: every page answers 200 at its old address with no missing text: `/`, `/dev`, `/floor`,
`/scenes`, a scene's page and `/setup`.

## Chunk 2: Fragments

Everything the browser loads into a page moves into `Html::` under `/html` (decision 1). The floor
item fragment moves to chunk 5, where the floor editor first needs it.

- [x] `app/controllers/html/lights_controller.rb` (`panel`, `pin`, moved from `LightsController`, which keeps `update`)
- [x] `app/controllers/html/custom_scenes_controller.rb` (`new`, `edit`, moved from `CustomScenesController`)
- [x] `app/views/html/custom_scenes/new.html.erb`, `edit.html.erb` (moved; their keys move under `html:`)
- [x] `config/routes.rb` (`namespace :html`: `/html/lights/:id/panel`, `/html/lights/:id/pin`, `/html/custom_scenes/new`, `/html/custom_scenes/:id/edit`)
- [x] `app/views/lights/_light.html.erb`, `app/views/floors/_light.html.erb`, `app/views/rooms/_room.html.erb`, `app/helpers/custom_scene_helper.rb` (the new URL helpers; the JavaScript reads URLs from the markup, so it doesn't change)
- [x] `test/controllers/html/lights_controller_test.rb`, `custom_scenes_controller_test.rb` (the fragment tests move here)

Live check: pin a light from its tile, open the floor's lamp panel at desktop and phone width, and
open the new and edit custom scene modals.

## Chunk 3: Presses

Everything that goes through `async_hue_call` answers JSON.

- [x] `app/controllers/api_controller.rb` (new: JSON only; with no bridge set up it answers 503 instead of redirecting)
- [x] `app/controllers/concerns/json_errors.rb` (new: 404, 409, 422 and 502 as in the table)
- [x] `app/services/house_commands/nothing_to_send.rb` (new: "nothing to change", "nothing to paint" and "no lights" are a 422, not a bridge error)
- [x] `app/controllers/concerns/hue_calls.rb` (202 is `{ light_ids, check_in_ms }`; busy raises for `JsonErrors`; no Turbo Streams, no `Check-In-After` header)
- [x] `LightsController`, `RoomsController`, `ScenesController`, `FloorPaintsController`, `CustomSceneActivationsController` (inherit `ApiController`)
- [x] `LightNamesController` (includes `HouseStreams` itself until chunk 4, since `HueCalls` no longer does)
- [x] `app/javascript/lib/requests.js` (`sendJson` turns bracketed field names into nested JSON; `readJson`)
- [x] `app/javascript/lib/hue_calls.js` (`asyncHueCall` sends JSON; a 409 or any error puts the tiles back from the copy saved before the guess and shows the error as a toast; a 202 clears old toasts. `directHueCall` stays on Turbo until chunk 4)
- [x] `app/javascript/lib/toasts.js` (`clearToasts`)
- [x] `app/javascript/controllers/async_hue_call_controller.js` (sends the form's real method)
- [x] `config/locales/en.yml` (the no-bridge message)
- [x] `test/controllers/api_errors_test.rb` (new), and the light, room, scene, paint and custom scene press tests check JSON

`ApplicationController` keeps its HTML behaviour (redirect to setup, bridge errors as Turbo Stream
toasts) for the controllers chunks 4 and 5 haven't moved yet; chunk 6 moves it into
`Html::ApplicationController`.

Live check: low-test-1 and low-test-2 from two tabs at once (the second gets a 409 and the toast),
a 409 snapping the guess back, and a light press sent as nested JSON.

## Chunk 4: Direct changes and edits

Renames, nicknames and custom scenes answer JSON; their changes reach the page by broadcast.

- [ ] `LightNamesController`, `RoomNamesController` (JSON; a nickname change broadcasts like a rename)
- [ ] `CustomScenesController` (JSON only: `show`, `create` from the current look, `update`, `destroy`, each broadcasting the room)
- [ ] `RoomsController#order` (stays 204)
- [ ] `app/javascript/controllers/direct_hue_call_controller.js`, `editor_controller.js` (JSON errors into the editor)
- [ ] `app/javascript/controllers/json_form_controller.js` (new)
- [ ] `custom_scene_dialog_controller.js` (saves with `json-form`, closes on success)
- [ ] Tests

Live check: rename the Kitchen lamp on `/dev` and back, nickname a light, save, rename and delete a
throwaway custom scene, reorder two rooms and put them back.

## Chunk 5: The floor and visibility

- [ ] `app/controllers/html/floor_objects_controller.rb` (new `show`: one floor item's HTML, for the editor to insert)
- [ ] `FloorsController#update`, `FloorObjectsController`, `FloorNetsController` (JSON; creating an object returns JSON, then the editor loads its fragment)
- [ ] `VisibilityController` (JSON, broadcasts everything; no redirect)
- [ ] `app/javascript/lib/floor/layout_editor.js`, `net_editor.js` (JSON replies)
- [ ] `app/javascript/controllers/autosave_controller.js` (becomes `json-form`)
- [ ] Tests

Live check: add, move and delete a floor object and a net; move a lamp; hide and show a light on
`/dev`.

## Chunk 6: Clean-up

- [ ] Remove what nothing uses any more: Turbo form handlers (`turbo:submit-end`), reply-only stream helpers, `format.html` branches
- [ ] `HouseStreams` and `ToastStreams` only build broadcasts
- [ ] `ApplicationController`'s HTML behaviour (redirect to setup, Turbo Stream bridge errors, browser and importmap checks) moves into `Html::ApplicationController`
- [ ] One test that every non-`Html::` controller only answers JSON

## Chunk 7: Docs

- [ ] `README.md` (the split, the reply table, where new endpoints go)
- [ ] `API_SPLIT_PLAN.md` (this file: everything ticked)

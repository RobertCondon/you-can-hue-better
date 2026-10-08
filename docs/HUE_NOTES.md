# The Hue bridge, as this app uses it

Everything here was checked against a real Hue Bridge on the local network.

## Getting a key

The bridge hands out an app key while its round link button is pressed:

    POST https://<bridge>/api
    {"devicetype": "you_can_hue_better#<host>", "generateclientkey": true}

Before the button is pressed it answers with error type 101 ("link button not pressed"). Within
30 seconds of a press it answers with `success.username` (the app key, sent as the
`hue-application-key` header on every v2 request) and `success.clientkey` (only needed for the
entertainment API). `GET https://<bridge>/api/0/config` needs no key and returns the bridge id.
The setup page does all of this (`Hue::LinkButtonPairing`).

Philips' discovery service, `https://discovery.meethue.com/`, lists the bridges on the same public
IP with their local addresses. It is rate limited and occasionally down, so the setup page treats it
as a suggestion and lets you type the address.

The bridge's certificate is self-signed, so the app does not verify it. Traffic never leaves the
local network. On macOS, an app needs Local Network permission (System Settings, Privacy & Security,
Local Network) before it can reach the bridge; without it requests fail with "no route to host"
while `ping` still works.

## CLIP v2

- Resources live at `https://<bridge>/clip/v2/resource/<type>[/<id>]`. The types this app reads are
  `light`, `grouped_light`, `room`, `zone`, `scene`, `smart_scene`, `device`, `button`,
  `relative_rotary`, `zigbee_connectivity` and `device_power`.
- Replies are `{"data": [...], "errors": [...]}`. A command to a bulb with no power still succeeds,
  but carries an error whose description mentions "communication issues": the bridge stored the
  command and will apply it when the bulb is back. The app treats that as a warning, not a failure
  (`Hue::ClipResponse`).
- Rooms contain devices; zones contain lights directly. Each room and zone has a `grouped_light`,
  which is what you PUT to change the whole group, and the bridge has one for the whole house
  (owner type `bridge_home`).
- Names are at most 32 characters. A bulb and the device that owns it are named separately.
- Scene recall takes an action: `active` sets the scene's static look, `dynamic_palette` plays its
  palette, `static` freezes a playing scene.
- `zigbee_connectivity` reports whether a device is reachable. The bridge keeps reporting a light's
  last state even when it has no power, so the app only counts a light as lit when its device is
  reachable.
- The bridge handles about ten light commands and one group command a second.

## The event stream

`GET https://<bridge>/eventstream/clip/v2` with `Accept: text/event-stream` is a server-sent event
stream. Each message's `data` is a JSON array of events, each with `id`, `creationtime`, `type`
(`update`, `add`, `delete`) and `data`: partial resources carrying only the fields that changed.
Light changes arrive within about a second, followed by recomputed `grouped_light` values for every
group the light is in. The bridge sends a `: hi` comment on connect and no regular keepalives, so the
app reconnects if the stream has been quiet for 40 seconds (`Hue::EventStream`) and treats the mirror
as stale after a minute without a heartbeat (`Hue::ListenerState`).

Button presses arrive as `button` events reporting `initial_press`, `repeat`, `short_release`,
`long_press` or `long_release`. The dial's ring arrives as `relative_rotary` events with a direction,
steps and duration.

## The legacy rules

Switches and the Tap Dial are driven by v1 rules stored on the bridge (`GET /api/<key>/rules`), not
by v2 behaviours. A button rule fires on a `buttonevent` condition whose value is the button number
times 1000 plus the event: 0 press, 1 hold, 2 short release, 3 long release. Scene cycles keep their
position in a hidden CLIP status sensor that resets after a few seconds idle. `bin/rails
hue:import_v1_rules` reads a dump of these rules and seeds the app's bindings from them
(`LegacyRulesImport`); the rules themselves are left untouched.

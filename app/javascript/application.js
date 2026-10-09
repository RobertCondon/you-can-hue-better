import "@hotwired/turbo-rails"
import "controllers"
import { deferStreamsAimedAtBusyElements } from "lib/busy"
import { sendHueTabWithTurboRequests } from "lib/hue_tab"
import { registerStreamActions } from "lib/stream_actions"

deferStreamsAimedAtBusyElements()
sendHueTabWithTurboRequests()
registerStreamActions()

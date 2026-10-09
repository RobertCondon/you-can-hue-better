import "@hotwired/turbo-rails"
import "controllers"
import { deferStreamsAimedAtBusyElements } from "lib/busy"
import { sendHueTabWithTurboRequests } from "lib/hue_tab"
import { registerStreamActions } from "lib/stream_actions"
import { freeLightsWhenSettled } from "lib/light_intents"

deferStreamsAimedAtBusyElements()
sendHueTabWithTurboRequests()
registerStreamActions()
freeLightsWhenSettled()

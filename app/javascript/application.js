import "@hotwired/turbo-rails"
import "controllers"
import { deferStreamsAimedAtBusyElements } from "lib/busy"

deferStreamsAimedAtBusyElements()

import { defer } from "lib/busy"
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// A live update must not replace a panel the person is in the middle of dragging.
document.addEventListener("turbo:before-stream-render", (event) => {
  const stream = event.target
  const target = stream.getAttribute("target") && document.getElementById(stream.getAttribute("target"))
  if (target?.dataset.busy) { defer(stream); event.preventDefault() }
})

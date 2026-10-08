require "puma/plugin"

# Owns the Hue listener thread. Lives outside app/ so it is never reloaded in development; the
# thread it starts resolves app classes fresh on every event.
# Disable with HUE_LISTENER=0.
module HueListenerThread
  module_function

  def start
    return if running?
    @stop = false
    @thread = Thread.new { ::Hue::Listener.new(stop: -> { @stop }).run }
    @thread.name = "hue-listener"
    @thread.report_on_exception = true
  end

  def stop
    @stop = true
    @thread&.join(10)
    @thread = nil
  end

  def running? = @thread&.alive? || false
end

Puma::Plugin.create do
  def start(launcher)
    launcher.events.on_booted { HueListenerThread.start }
    launcher.events.on_stopped { HueListenerThread.stop }
  end
end

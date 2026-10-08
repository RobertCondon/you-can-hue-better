require "puma/plugin"

module HueListenerThread
  THREAD_NAME = "hue-listener"
  STOP_TIMEOUT_SECONDS = 10

  module_function

  def start
    return if running?

    @stop_requested = false
    @thread = Thread.new { ::Hue::Listener.new(stop: -> { @stop_requested }).run }
    @thread.name = THREAD_NAME
    @thread.report_on_exception = true
  end

  def stop
    @stop_requested = true
    @thread&.join(STOP_TIMEOUT_SECONDS)
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

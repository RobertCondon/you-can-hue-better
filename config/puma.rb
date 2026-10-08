require_relative "../lib/puma/plugin/hue_listener"

threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count
port ENV.fetch("PORT", 3000)

plugin :tmp_restart
plugin :hue_listener unless ENV["HUE_LISTENER"] == "0"

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

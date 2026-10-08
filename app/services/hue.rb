module Hue
  # Single client for the app. Tests swap this for a fake.
  def self.client
    @client ||= Client.new
  end

  # A client set from outside (the test fake) is pinned: a reset leaves it alone.
  def self.client=(client)
    @client = client
    @pinned = !client.nil?
  end

  # After pairing (or a config change) the next caller gets a client built from the new config.
  def self.reset!
    @client = nil unless @pinned
  end

  def self.configured? = Config.load.configured?
end

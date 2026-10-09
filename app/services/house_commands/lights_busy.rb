module HouseCommands
  class LightsBusy < StandardError
    attr_reader :busy

    def initialize(busy)
      @busy = busy
      super(busy.target_name)
    end
  end
end

module HouseCommands
  class Outcome < Data.define(:result, :undo)
    delegate :unreachable_lights?, to: :result
  end
end

class Floor
  module Coordinates
    POSITION_RANGE = 0..100
    SIZE_RANGE = 1..100
    DECIMAL_PLACES = 2

    module_function

    def position(value) = value.to_f.clamp(POSITION_RANGE).round(DECIMAL_PLACES)
    def size(value) = value.to_f.clamp(SIZE_RANGE).round(DECIMAL_PLACES)
  end
end

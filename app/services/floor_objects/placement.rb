module FloorObjects
  class Placement
    def initialize(floor_object)
      @floor_object = floor_object
    end

    def apply(changes)
      @floor_object.update!(
        x: FloorCoordinates.position(changes[:x]), y: FloorCoordinates.position(changes[:y]),
        w: FloorCoordinates.size(changes[:w]), h: FloorCoordinates.size(changes[:h]),
        rotation: changes.key?(:rotation) ? changes[:rotation].to_i % FloorObject::FULL_TURN_DEGREES : @floor_object.rotation,
        label: changes.key?(:label) ? changes[:label].to_s.strip.presence : @floor_object.label
      )
    end
  end
end

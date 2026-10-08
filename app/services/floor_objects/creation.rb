module FloorObjects
  module Creation
    FLOOR_CENTRE = 50
    HALF = 2.0

    module_function

    def call(group_id:, kind:)
      size = FloorObject::DEFAULT_SIZES.fetch(kind) { raise FloorObject::UnknownKind, kind }
      FloorObject.create!(group_id:, kind:, x: FLOOR_CENTRE - size[:w] / HALF, y: FLOOR_CENTRE - size[:h] / HALF, **size)
    end
  end
end

module Undo
  module Capture
    module_function

    def call(description, light_ids)
      UndoAction.expired.delete_all
      light_states = Hue::Light.where(id: light_ids).includes(:device).map { |light| LightState.of(light).to_h }
      UndoAction.create!(description:, states: light_states)
    end
  end
end

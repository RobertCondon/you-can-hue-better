module CustomSceneHelper
  NAME_LENGTH = Hue::Api::Limits::NAME_LENGTH
  HOLD_CONTROLLER = "scene-hold"
  HOLD_ACTIONS = [
    "pointerdown->scene-hold#start", "pointermove->scene-hold#move", "pointerup->scene-hold#cancel",
    "pointercancel->scene-hold#cancel", "pointerleave->scene-hold#cancel", "contextmenu->scene-hold#menu",
    "click->scene-hold#guard:capture", "scene-hold:edit->custom-scene-dialog#open"
  ].join(" ").freeze

  def custom_scene_chip_data(scene)
    { controller: HOLD_CONTROLLER, action: HOLD_ACTIONS, custom_scene_dialog_url_param: edit_custom_scene_path(scene.id), **scene_set_data(scene.targets) }
  end
end

module ScenesByRoom
  UNARRANGED_POSITION = Float::INFINITY

  module_function

  def call
    Hue::Scene.recallable.includes(:extension, :group, actions: { light: :extension }).group_by(&:group_id).transform_values do |scenes|
      scenes.sort_by { |scene| [ scene.extension&.position || UNARRANGED_POSITION, scene.display_name ] }
    end
  end
end

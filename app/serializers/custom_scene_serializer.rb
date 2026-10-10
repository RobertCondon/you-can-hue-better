class CustomSceneSerializer
  include Alba::Resource

  attributes :id, :name, :group_id, :transition_ms

  many :lights, resource: CustomSceneLightSerializer
end

require "test_helper"

class Hue::Api::ClientTest < ActiveSupport::TestCase
  test "each resource reads from its own path" do
    assert_equal %w[l1 l2], Hue.client.lights.all.map { |light| light["id"] }
    assert_equal "Desk lamp", Hue.client.lights.find("l1").dig("metadata", "name")
    assert_equal %w[rot], Hue.client.relative_rotaries.all.map { |rotary| rotary["id"] }
  end

  test "lights and grouped lights take changes" do
    Hue.client.lights.update("l2", { on: { on: true } })
    Hue.client.grouped_lights.update("g1", { on: { on: false } })
    assert_equal [ [ :light, "l2", { on: { on: true } } ], [ :grouped_light, "g1", { on: { on: false } } ] ], hue.writes
  end

  test "lights, devices, rooms and zones can be renamed; read-only resources cannot" do
    Hue.client.groups_of_type(Hue::Api::ResourceType::ZONE).rename("z1", "Night")
    assert_equal [ [ :rename_group, "zone", "z1", "Night" ] ], hue.writes
    [ :lights, :devices, :rooms, :zones ].each { |resources| assert_respond_to Hue.client.public_send(resources), :rename }
    [ :buttons, :relative_rotaries, :scenes ].each { |resources| refute_respond_to Hue.client.public_send(resources), :rename }
    refute_respond_to Hue.client.rooms, :update
  end

  test "scenes are recalled, statically by default" do
    result = Hue.client.scenes.recall("s1")
    Hue.client.scenes.recall("s2", action: Hue::Api::SceneRecall::PLAY_PALETTE)
    assert_equal [ [ :scene, "s1", "active" ], [ :scene, "s2", "dynamic_palette" ] ], hue.writes
    refute result.unreachable_lights?
  end

  test "an unpowered bulb comes back as a warning on the command" do
    hue.unpowered_light_ids << "l1"
    assert Hue.client.lights.update("l1", { on: { on: true } }).unreachable_lights?
  end
end

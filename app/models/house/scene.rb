# A bridge scene, as reported right now.
class House::Scene < Data.define(:id, :name, :group_id)
  def self.from_api(json)
    new(id: json["id"], name: json.dig("metadata", "name"), group_id: json.dig("group", "rid"))
  end
end

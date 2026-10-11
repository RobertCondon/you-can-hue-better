class FloorItemSerializer
  include Alba::Resource

  attributes :id, :kind, :label

  attribute(:x) { |item| item.x.to_f }
  attribute(:y) { |item| item.y.to_f }
  attribute(:w) { |item| item.w.to_f }
  attribute(:h) { |item| item.h.to_f }
  attribute(:rotation) { |item| item.rotation.to_f }
end

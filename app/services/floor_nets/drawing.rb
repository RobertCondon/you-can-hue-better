module FloorNets
  module Drawing
    module_function

    def create!(attributes)
      net = FloorNet.new(attributes)
      FloorNet.transaction do
        FloorNet.outlines.delete_all if net.outline?
        net.save!
      end
      net
    end
  end
end

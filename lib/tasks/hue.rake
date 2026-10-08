namespace :hue do
  desc "Rebuild the hue_* mirror tables from the bridge"
  task sync: :environment do
    counts = Hue::Sync.run
    puts counts.map { |k, v| "#{k}: #{v}" }.join(", ")
  end

  desc "Seed bindings from the bridge's legacy v1 rules (default: data/v1-rules.json)"
  task :import_v1_rules, [ :path ] => :environment do |_, args|
    path = args[:path] || Rails.root.join("data/v1-rules.json")
    result = LegacyRulesImport.run(JSON.parse(File.read(path)))
    puts "#{result.bindings.size} bindings:"
    result.bindings.each do |b|
      steps = b.steps.any? ? " [#{b.scenes.map(&:name).join(" > ")}]" : ""
      puts "  #{b.control.label.ljust(34)} #{b.gesture.ljust(14)} #{b.action.ljust(17)} #{b.target&.name}#{steps} #{b.settings.presence || ""}"
    end
    puts "#{result.skipped.size} rule groups skipped:" if result.skipped.any?
    result.skipped.each { puts "  rules #{_1[:rules].join(",")}: #{_1[:reason]}" }
  end
end

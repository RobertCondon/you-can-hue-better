namespace :hue do
  default_rules_path = "data/v1-rules.json"

  desc "Rebuild the hue_* mirror tables from the bridge"
  task sync: :environment do
    puts Hue::Mirror::Sync.call.map { |table, count| "#{table}: #{count}" }.join(", ")
  end

  desc "Seed bindings from the bridge's legacy v1 rules (default: #{default_rules_path})"
  task :import_v1_rules, [ :path ] => :environment do |_task, arguments|
    rules_path = arguments[:path] || Rails.root.join(default_rules_path)
    puts LegacyRulesImport::Report.new(LegacyRulesImport.call(JSON.parse(File.read(rules_path)))).lines
  end
end

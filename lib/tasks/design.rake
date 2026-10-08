namespace :design do
  desc "Rebuild design/_app.css from the app's stylesheets, in load order, for the design preview pages"
  task stylesheet: :environment do
    stylesheet_directory = Rails.root.join("app/assets/stylesheets")
    tokens = ApplicationController.helpers.light_colour_tokens
    combined = [ tokens, *ApplicationHelper::STYLESHEETS.map { |name| stylesheet_directory.join("#{name}.css").read } ].join("\n")
    Rails.root.join("design/_app.css").write(combined)
    puts "design/_app.css rebuilt from #{ApplicationHelper::STYLESHEETS.size} stylesheets"
  end
end

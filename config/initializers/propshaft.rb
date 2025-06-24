# Configure Propshaft asset pipeline for Rails 8
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "stylesheets")
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "javascript")
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "images")
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "fonts")

# Ensure assets are properly served in production
if Rails.env.production?
  Rails.application.config.assets.compile = false
  Rails.application.config.assets.digest = true
end

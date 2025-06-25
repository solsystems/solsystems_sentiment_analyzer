source "https://rubygems.org"

# Core Rails
gem "rails", "~> 8.0.2"
gem "puma", ">= 5.0"
gem "jbuilder"
gem "yard"

# Database
gem "sqlite3"

# Asset pipeline and frontend
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Utilities
gem "dotenv-rails", groups: [:development, :test]
gem "roo"
gem "csv"
gem "openai"
gem "prawn"
gem "prawn-table"
gem "selenium-webdriver"
gem "webdrivers"

# Caching, background jobs, and other Rails features
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false

gem "kamal", require: false
# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma
# [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  gem "rspec-rails"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

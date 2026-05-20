source "https://rubygems.org"

ruby "~> 3.3.0"

# Core
gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Background Jobs
gem "solid_queue"

# API
gem "rack-cors", "~> 3.0"
gem "jwt", "~> 2.7"
gem "bcrypt", "~> 3.1"

# Environment Variables
gem "dotenv-rails", "~> 3.0"

# Performance
gem "bootsnap", require: false
gem "oj", "~> 3.16"

# Windows timezone data
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers", "~> 6.0"
end

source "https://rubygems.org"

ruby ">= 3.2.0"
gem "rails", "~> 8.1.4"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 6.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

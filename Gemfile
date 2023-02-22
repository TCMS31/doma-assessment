source "https://rubygems.org"

ruby ">= 3.4.0"

# Rails and the asset toolchain
gem "rails", "~> 8.1.0"
gem "sprockets-rails"                 # asset manifest / digest pipeline
gem "jsbundling-rails"                # esbuild -> app/assets/builds
gem "cssbundling-rails"               # tailwindcss -> app/assets/builds
gem "turbo-rails"
gem "stimulus-rails"

# Data + server
gem "pg", "~> 1.5"
gem "puma", ">= 6.4"

# Boot time
gem "bootsnap", require: false

# Windows does not ship zoneinfo files
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

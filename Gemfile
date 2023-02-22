source "https://rubygems.org"

ruby ">= 3.1.0"

# Rails and the asset toolchain
gem "rails", "~> 7.0.4", ">= 7.0.4.2"
gem "sprockets-rails"                 # asset manifest / digest pipeline
gem "jsbundling-rails"                # esbuild -> app/assets/builds
gem "cssbundling-rails"               # tailwindcss -> app/assets/builds
gem "turbo-rails"
gem "stimulus-rails"

# Data + server
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "redis", "~> 4.0"                 # Action Cable adapter in production

# Boot time
gem "bootsnap", require: false

# Rails 7.0's JSON encoder calls JSON.generate(quirks_mode:), removed in json 3.x.
# RuboCop resolves json >= 2.3, so pin the 2.x line explicitly.
gem "json", "~> 2.7"

# Windows does not ship zoneinfo files
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

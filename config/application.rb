require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DomaTest
  class Application < Rails::Application
    config.load_defaults 7.0

    # Where the questionnaire is loaded from. See config/initializers/quiz.rb
    # for the registry of available source adapters.
    config.quiz = ActiveSupport::OrderedOptions.new
    config.quiz.source = ENV.fetch("QUESTIONNAIRE_SOURCE", "json_file").to_sym
    config.quiz.path   = ENV.fetch("QUESTIONNAIRE_PATH") { Rails.root.join("data.json").to_s }

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end

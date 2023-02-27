ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module QuestionnaireHelpers
  # The suite runs against the questionnaire the exercise actually ships with,
  # so a change to data.json that breaks the app breaks the build.
  def import_questionnaire!
    Quiz::Importer.call
  end

  def build_conclusion(name, *contexts)
    Conclusion.create!(name: name, context: contexts)
  end

  # Counts the application's own SQL statements, ignoring schema reflection and
  # transaction bookkeeping.
  def count_queries(&block)
    queries = []
    counter = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:sql].match?(/\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i)

      queries << payload[:sql]
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    queries
  end
end

class ActiveSupport::TestCase
  include QuestionnaireHelpers
end

class ActionDispatch::IntegrationTest
  include QuestionnaireHelpers
end

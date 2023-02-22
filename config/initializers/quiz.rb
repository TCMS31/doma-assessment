# Register the questionnaire source adapters this application ships with.
# See app/services/quiz/sources.rb for how to add another.
Rails.application.config.to_prepare do
  Quiz::Sources.register(:json_file) { |path:| Quiz::Sources::JsonFile.new(path) }
end

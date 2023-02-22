# Seeding is a thin wrapper around the questionnaire import so that
# `bin/rails db:setup` produces a usable application in one step.
report = Quiz::Importer.call
puts report

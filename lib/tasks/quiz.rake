namespace :quiz do
  desc "Import the questionnaire from QUESTIONNAIRE_SOURCE (default: the JSON file at QUESTIONNAIRE_PATH)"
  task import: :environment do
    report = Quiz::Importer.call
    puts report
  end

  desc "Print every route through the questionnaire and the conclusion each one reaches"
  task paths: :environment do
    graph = Quiz::Graph.current
    abort "No questionnaire imported. Run `bin/rails quiz:import` first." if graph.root.nil?

    graph.context_paths.each do |contexts|
      result = Quiz::ConclusionMatcher.call(contexts)
      verdict = result.conclusive? ? result.conclusion.name : "inconclusive (closest: #{result.best&.conclusion&.name})"
      puts format("%-48s -> %s", contexts.join(" + "), verdict)
    end
  end
end

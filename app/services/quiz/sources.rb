module Quiz
  # Registry of questionnaire source adapters.
  #
  # A source is any object that responds to `#questions` and `#conclusions`,
  # each returning plain hashes in the shape documented on
  # Quiz::Sources::JsonFile. Registering a new one is the extension seam for
  # loading questionnaires from somewhere other than a bundled JSON file
  # (a CMS, an HTTP API, a YAML directory) without touching the importer,
  # the matcher or the controller.
  #
  #   Quiz::Sources.register(:http) { |url:| MyHttpSource.new(url) }
  #   QUESTIONNAIRE_SOURCE=http QUESTIONNAIRE_PATH=https://... bin/rails quiz:import
  module Sources
    class UnknownSource < StandardError; end

    class << self
      def register(name, &builder)
        raise ArgumentError, "a block building the source is required" unless builder

        registry[name.to_sym] = builder
      end

      def build(name, **options)
        builder = registry.fetch(name.to_sym) do
          raise UnknownSource, "unknown questionnaire source #{name.inspect}; " \
                               "registered: #{registered.inspect}"
        end
        builder.call(**options)
      end

      def registered
        registry.keys
      end

      # Builds the source selected by config/application.rb (env-driven).
      def default
        build(Rails.application.config.quiz.source, path: Rails.application.config.quiz.path)
      end

      private

      def registry
        @registry ||= {}
      end
    end
  end
end

module Quiz
  module Sources
    # Reads a questionnaire from a JSON document on disk.
    #
    # Expected shape (this is the format of the questionnaire supplied with
    # the exercise, see data.json):
    #
    #   {
    #     "questions": [
    #       { "id": "q1",
    #         "question": "Does it have a tail",
    #         "answers": {
    #           "yes": { "context": "tail",    "question_id": "q2" },
    #           "no":  { "context": "no tail", "question_id": "q3" }
    #         } }
    #     ],
    #     "conclusions": [
    #       { "conclusion": "loris", "context": ["tail", "nocturnal"] }
    #     ]
    #   }
    #
    # An answer with no "question_id" terminates the walk.
    class JsonFile
      class InvalidDocument < StandardError; end

      attr_reader :path

      def initialize(path)
        @path = Pathname.new(path.to_s)
      end

      def questions
        document.fetch("questions", []).map do |question|
          {
            external_id: question["id"],
            statement: question["question"],
            answers: Array(question["answers"]).map do |answer_type, answer|
              {
                answer_type: answer_type,
                context: answer["context"],
                next_question_external_id: answer["question_id"]
              }
            end
          }
        end
      end

      def conclusions
        document.fetch("conclusions", []).map do |conclusion|
          { name: conclusion["conclusion"], context: Array(conclusion["context"]) }
        end
      end

      def description
        "JSON file #{path}"
      end

      private

      def document
        @document ||= begin
          raise InvalidDocument, "questionnaire not found at #{path}" unless path.exist?

          parsed = JSON.parse(path.read)
          raise InvalidDocument, "questionnaire at #{path} must be a JSON object" unless parsed.is_a?(Hash)

          parsed
        rescue JSON::ParserError => e
          raise InvalidDocument, "questionnaire at #{path} is not valid JSON: #{e.message}"
        end
      end
    end
  end
end

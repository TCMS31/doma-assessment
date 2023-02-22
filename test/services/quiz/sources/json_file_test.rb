require "test_helper"

module Quiz
  module Sources
    class JsonFileTest < ActiveSupport::TestCase
      setup { @source = JsonFile.new(Rails.root.join("data.json")) }

      test "maps the document's questions onto the importer's vocabulary" do
        first = @source.questions.first

        assert_equal "q1", first[:external_id]
        assert_equal "Does it have a tail", first[:statement]
        assert_equal(
          [ { answer_type: "yes", context: "tail", next_question_external_id: "q2" },
           { answer_type: "no", context: "no tail", next_question_external_id: "q3" } ],
          first[:answers]
        )
      end

      test "a terminal answer has no next question" do
        last = @source.questions.last

        assert(last[:answers].all? { |answer| answer[:next_question_external_id].nil? })
      end

      test "maps conclusions" do
        assert_equal(
          { name: "lemur", context: [ "tail", "long tail (> 2in)", "diurnal" ] },
          @source.conclusions.last
        )
      end

      test "a missing file is reported with its path" do
        error = assert_raises(JsonFile::InvalidDocument) { JsonFile.new("/no/such/file.json").questions }

        assert_includes error.message, "/no/such/file.json"
      end

      test "malformed JSON is reported rather than crashing mid-import" do
        path = Rails.root.join("tmp", "broken-questionnaire.json")
        path.write("{ nope")

        assert_raises(JsonFile::InvalidDocument) { JsonFile.new(path).questions }
      ensure
        path&.delete if path&.exist?
      end

      test "a JSON document that is not an object is rejected" do
        path = Rails.root.join("tmp", "array-questionnaire.json")
        path.write("[]")

        assert_raises(JsonFile::InvalidDocument) { JsonFile.new(path).questions }
      ensure
        path&.delete if path&.exist?
      end
    end
  end
end

require "test_helper"

module Quiz
  class ImporterTest < ActiveSupport::TestCase
    # A source is anything answering #questions and #conclusions, so the tests
    # can drive the importer without touching the filesystem.
    Stub = Struct.new(:questions, :conclusions) do
      def description = "stub source"
    end

    test "imports the questionnaire shipped with the exercise" do
      report = import_questionnaire!

      assert_equal [ 3, 6, 2 ], [ report.questions, report.answers, report.conclusions ]
      assert_equal 3, Question.count
      assert_equal 6, Answer.count
      assert_equal 2, Conclusion.count
      assert_includes report.to_s, "data.json"
    end

    test "is idempotent" do
      import_questionnaire!

      assert_no_difference [ "Question.count", "Answer.count", "Conclusion.count" ] do
        import_questionnaire!
      end
    end

    test "updates rows in place when the source changes" do
      import_questionnaire!
      original_id = Question.find_by!(external_id: "q1").id

      Importer.call(source: Stub.new(
        [ { external_id: "q1", statement: "Reworded",
           answers: [ { answer_type: "yes", context: "tail", next_question_external_id: nil } ] } ],
        [ { name: "loris", context: %w[tail] } ]
      ))

      question = Question.find_by!(external_id: "q1")
      assert_equal original_id, question.id
      assert_equal "Reworded", question.statement
    end

    test "prunes questions, answers and conclusions the source no longer contains" do
      import_questionnaire!

      Importer.call(source: Stub.new(
        [ { external_id: "q1", statement: "Does it have a tail",
           answers: [ { answer_type: "yes", context: "tail", next_question_external_id: nil } ] } ],
        [ { name: "loris", context: %w[tail] } ]
      ))

      assert_equal %w[q1], Question.ordered.pluck(:external_id)
      assert_equal %w[yes], Answer.pluck(:answer_type)
      assert_equal %w[loris], Conclusion.ordered.pluck(:name)
    end

    test "refuses a questionnaire whose answers point at questions that do not exist" do
      error = assert_raises(Importer::InvalidQuestionnaire) do
        Importer.call(source: Stub.new(
          [ { external_id: "q1", statement: "Does it have a tail",
             answers: [ { answer_type: "yes", context: "tail", next_question_external_id: "q99" } ] } ],
          [ { name: "loris", context: %w[tail] } ]
        ))
      end

      assert_includes error.message, "q99"
    end

    test "refuses an empty questionnaire" do
      assert_raises(Importer::InvalidQuestionnaire) { Importer.call(source: Stub.new([], [])) }
    end

    test "refuses a question with no answers" do
      assert_raises(Importer::InvalidQuestionnaire) do
        Importer.call(source: Stub.new([ { external_id: "q1", statement: "?", answers: [] } ], []))
      end
    end

    test "a failed import leaves the database untouched" do
      import_questionnaire!

      assert_no_difference "Question.count" do
        assert_raises(Importer::InvalidQuestionnaire) do
          Importer.call(source: Stub.new(
            [ { external_id: "new", statement: "New", answers: [ { answer_type: "yes", context: "c", next_question_external_id: "gone" } ] } ],
            []
          ))
        end
      end
      assert_equal %w[q1 q2 q3], Question.ordered.pluck(:external_id)
    end
  end
end

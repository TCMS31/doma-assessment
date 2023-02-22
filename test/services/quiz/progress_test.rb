require "test_helper"

module Quiz
  class ProgressTest < ActiveSupport::TestCase
    setup do
      import_questionnaire!
      @session = {}
      @progress = Progress.new(@session)
      @q1 = Question.find_by!(external_id: "q1")
      @q3 = Question.find_by!(external_id: "q3")
    end

    test "starts empty" do
      assert_not_predicate @progress, :started?
      assert_empty @progress.contexts
      assert_equal 0, @progress.answered_count
    end

    test "records the statement and the context of each answer" do
      @progress.record(@q1, @q1.answers.find_by!(answer_type: "no"))

      assert_predicate @progress, :started?
      assert_equal [ "no tail" ], @progress.contexts
      assert_equal "Does it have a tail", @progress.steps.first["statement"]
    end

    test "re-answering an earlier question discards the answers that followed it" do
      @progress.record(@q1, @q1.answers.find_by!(answer_type: "yes"))
      @progress.record(@q3, @q3.answers.find_by!(answer_type: "yes"))
      assert_equal [ "tail", "nocturnal" ], @progress.contexts

      @progress.record(@q1, @q1.answers.find_by!(answer_type: "no"))

      assert_equal [ "no tail" ], @progress.contexts
    end

    test "reset clears the run" do
      @progress.record(@q1, @q1.answers.first)
      @progress.reset!

      assert_not_predicate @progress, :started?
      assert_empty @session[Progress::KEY]
    end

    test "survives a session that has been serialised to JSON and back" do
      @progress.record(@q1, @q1.answers.first)
      round_tripped = JSON.parse(@session.to_json)

      assert_equal @progress.contexts, Progress.new(round_tripped).contexts
    end

    test "a session holding junk under the key is replaced rather than raising" do
      assert_nothing_raised { Progress.new({ Progress::KEY => "not an array" }) }
      assert_empty Progress.new({ Progress::KEY => nil }).steps
    end
  end
end

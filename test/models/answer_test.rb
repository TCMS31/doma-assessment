require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  setup { @question = Question.create!(external_id: "q1", statement: "Does it have a tail") }

  test "requires an answer type and a context" do
    answer = @question.answers.new
    assert_not answer.valid?
    assert_includes answer.errors.attribute_names, :answer_type
    assert_includes answer.errors.attribute_names, :context
  end

  test "a question cannot carry the same answer type twice" do
    @question.answers.create!(answer_type: "yes", context: "tail")
    duplicate = @question.answers.new(answer_type: "yes", context: "tail again")

    assert_not duplicate.valid?
  end

  test "an answer with no next question terminates the run" do
    terminal = @question.answers.create!(answer_type: "yes", context: "nocturnal")
    onward = @question.answers.create!(answer_type: "no", context: "diurnal", next_question_external_id: "q2")

    assert_predicate terminal, :terminal?
    assert_not_predicate onward, :terminal?
  end

  test "label humanises the source's answer key" do
    answer = @question.answers.create!(answer_type: "yes", context: "tail")

    assert_equal "Yes", answer.label
  end

  test "answer types are not limited to yes and no" do
    answer = @question.answers.create!(answer_type: "sometimes", context: "occasionally nocturnal")

    assert_predicate answer, :valid?
    assert_equal "Sometimes", answer.label
  end
end

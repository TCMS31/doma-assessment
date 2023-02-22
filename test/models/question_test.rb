require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "requires an external id and a statement" do
    question = Question.new
    assert_not question.valid?
    assert_includes question.errors.attribute_names, :external_id
    assert_includes question.errors.attribute_names, :statement
  end

  test "external ids are unique" do
    Question.create!(external_id: "q1", statement: "Does it have a tail")
    duplicate = Question.new(external_id: "q1", statement: "Something else")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :external_id
  end

  test "root is the first imported question" do
    import_questionnaire!

    assert_equal "q1", Question.root.external_id
  end

  test "answers come back in a stable order" do
    import_questionnaire!

    assert_equal %w[yes no], Question.root.answers.map(&:answer_type)
  end

  test "to_param uses the external id so routes read q1 rather than a row id" do
    import_questionnaire!

    assert_equal "q1", Question.root.to_param
  end

  test "destroying a question destroys its answers" do
    import_questionnaire!

    assert_difference -> { Answer.count }, -2 do
      Question.root.destroy
    end
  end
end

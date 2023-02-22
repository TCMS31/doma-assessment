require "test_helper"

# A verdict is only meaningful for a run that followed the tree from the first
# question to an answer that ends it. These cover the ways a visitor could
# otherwise get a result from a partial run.
class RunOrderTest < ActionDispatch::IntegrationTest
  setup { import_questionnaire! }

  def answer(question, label)
    post submit_answer_questions_path, params: { answer: label, question: question }
  end

  test "the result page sends an unfinished run back to its next question" do
    get questions_path
    answer "q1", "no"

    get result_questions_path

    assert_redirected_to questions_path(question: "q3")
  end

  test "a deep link past the start sends a new visitor to the first question" do
    get questions_path(question: "q3")

    assert_redirected_to questions_path
    assert_equal "Questions are answered in order, so you have been taken to the next one.", flash[:alert]
  end

  test "a deep link past the next question sends the visitor to the next question" do
    get questions_path
    answer "q1", "yes"

    get questions_path(question: "q3")

    assert_redirected_to questions_path(question: "q2")
  end

  test "an answer to a question that has not been reached is not recorded" do
    get questions_path
    answer "q3", "yes"

    assert_redirected_to questions_path
    get result_questions_path
    assert_redirected_to questions_path
  end

  test "an earlier question stays reachable so an answer can be changed" do
    get questions_path
    answer "q1", "yes"
    answer "q2", "yes"

    get questions_path(question: "q2")
    assert_response :success

    answer "q2", "no"
    assert_redirected_to questions_path(question: "q3")
  end
end

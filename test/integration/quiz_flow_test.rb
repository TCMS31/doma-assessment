require "test_helper"

class QuizFlowTest < ActionDispatch::IntegrationTest
  setup { import_questionnaire! }

  def answer(question, label)
    post submit_answer_questions_path, params: { answer: label, question: question }
  end

  test "the homepage advertises what has been imported" do
    get root_path

    assert_response :success
    assert_select "h1", "Which animal is it?"
    assert_select "dd", text: "3 questions"
    assert_select "dd", text: "2 possible animals"
  end

  test "a short-tailed nocturnal animal with a tail is a loris" do
    get questions_path
    assert_response :success
    assert_select "h1", "Does it have a tail?"

    answer "q1", "yes"
    assert_redirected_to questions_path(question: "q2")
    follow_redirect!
    assert_select "h1", "Is it a long tail (> 2in)?"

    answer "q2", "no"
    assert_redirected_to questions_path(question: "q3")
    follow_redirect!

    answer "q3", "yes"
    assert_redirected_to result_questions_path
    follow_redirect!

    assert_response :success
    assert_select "h1", "loris"
    assert_select "section", /identifies this as a loris/
  end

  test "a long-tailed diurnal animal is a lemur" do
    get questions_path
    answer "q1", "yes"
    answer "q2", "yes"
    answer "q3", "no"
    follow_redirect!

    assert_select "h1", "lemur"
  end

  test "a tail-less diurnal animal is reported as inconclusive with the closest match" do
    get questions_path
    answer "q1", "no"
    answer "q3", "no"
    follow_redirect!

    assert_response :success
    assert_select "h1", "No animal in the questionnaire matches every answer."
    assert_select "section", /Closest match:\s*lemur/
    assert_select "section", /Not accounted for:\s*no tail/
  end

  test "the answer trail is shown on the way through and on the result" do
    get questions_path
    answer "q1", "no"
    follow_redirect!

    assert_select "ol li", /Does it have a tail\?\s*No\s*— no tail/

    answer "q3", "yes"
    follow_redirect!
    assert_select "ol li", count: 2
  end

  test "returning to the first question starts a fresh run" do
    get questions_path
    answer "q1", "yes"
    answer "q2", "yes"

    get questions_path
    assert_response :success
    assert_select "ol li", count: 0

    answer "q1", "no"
    answer "q3", "yes"
    follow_redirect!

    assert_select "h1", "loris"
    assert_select "ol li", count: 2
  end

  test "re-answering an earlier question discards the answers that followed it" do
    get questions_path
    answer "q1", "yes"
    answer "q2", "yes"

    answer "q1", "no"
    assert_redirected_to questions_path(question: "q3")
    follow_redirect!

    assert_select "ol li", count: 1
    assert_select "ol li", /no tail/
  end

  test "an answer the question does not offer is rejected" do
    get questions_path
    answer "q1", "maybe"

    assert_redirected_to questions_path
    assert_equal "That answer is not available for this question.", flash[:alert]
  end

  test "an unknown question sends the visitor home" do
    get questions_path(question: "q99")

    assert_redirected_to root_path
    assert_equal "That question is not part of the questionnaire.", flash[:alert]
  end

  test "the result page redirects when nothing has been answered" do
    get result_questions_path

    assert_redirected_to questions_path
  end

  test "the result survives a reload" do
    get questions_path
    answer "q1", "no"
    answer "q3", "yes"

    get result_questions_path
    assert_response :success
    assert_select "h1", "loris"

    get result_questions_path
    assert_response :success
    assert_select "h1", "loris"
  end

  test "a question page issues two queries, not one per imported row" do
    get questions_path # warm the session and the Rails caches

    queries = count_queries { get questions_path(question: "q2") }

    assert_response :success
    assert_equal 2, queries.size,
                 "the questionnaire import used to run on every request; got:\n#{queries.join("\n")}"
  end

  test "an empty database does not blow up the question page" do
    Question.destroy_all

    get questions_path

    assert_redirected_to root_path
  end
end

require "test_helper"

class PageChromeTest < ActionDispatch::IntegrationTest
  test "pages send a strict content security policy" do
    get root_path

    policy = response.headers["Content-Security-Policy"]
    assert_includes policy, "default-src 'self'"
    assert_includes policy, "object-src 'none'"
    assert_includes policy, "frame-ancestors 'none'"
    assert_not_includes policy, "unsafe-inline"
  end

  test "views carry no inline style attributes, which the policy would block" do
    import_questionnaire!
    get questions_path
    post submit_answer_questions_path, params: { question: "q1", answer: "no" }
    post submit_answer_questions_path, params: { question: "q3", answer: "yes" }
    follow_redirect!

    assert_select "[style]", count: 0
    assert_select "progress", count: 2
  end

  test "the homepage explains how to import when nothing has been imported" do
    get root_path

    assert_response :success
    assert_select "p", "Nothing to ask yet"
    assert_select "code", "bin/rails quiz:import"
    assert_select "a[href=?]", questions_path, count: 0
  end

  test "question progress is a labelled native progress bar" do
    import_questionnaire!

    get questions_path

    assert_select "progress[max='3'][value='1'][aria-label=?]", "Question 1 of 3"
  end

  test "every page offers a skip link to the main content" do
    get root_path

    assert_select "a[href='#content']", "Skip to content"
    assert_select "main#content"
  end
end

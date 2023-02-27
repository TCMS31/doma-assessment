require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "reports ok and how much of the questionnaire is loaded" do
    import_questionnaire!

    get health_path

    assert_response :success
    assert_equal({ "status" => "ok", "questions" => 3 }, response.parsed_body)
  end

  test "reports ok with an empty questionnaire" do
    get health_path

    assert_response :success
    assert_equal 0, response.parsed_body["questions"]
  end
end

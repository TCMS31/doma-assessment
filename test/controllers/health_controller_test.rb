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

  test "reports 503 with the error class when the database is unreachable" do
    connection = ActiveRecord::Base.lease_connection
    connection.define_singleton_method(:select_value) do |*|
      raise ActiveRecord::ConnectionNotEstablished, "connection refused"
    end

    get health_path

    assert_response :service_unavailable
    assert_equal({ "status" => "error", "error" => "ActiveRecord::ConnectionNotEstablished" }, response.parsed_body)
  ensure
    connection.singleton_class.remove_method(:select_value)
  end
end

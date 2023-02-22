require "test_helper"

module Quiz
  class SourcesTest < ActiveSupport::TestCase
    test "the json_file adapter is registered out of the box" do
      assert_includes Sources.registered, :json_file
    end

    test "the default source follows the application configuration" do
      assert_instance_of Sources::JsonFile, Sources.default
      assert_equal Rails.application.config.quiz.path.to_s, Sources.default.path.to_s
    end

    test "a new source can be registered and built" do
      Sources.register(:memory) { |path:| Struct.new(:path).new(path) }

      assert_includes Sources.registered, :memory
      assert_equal "wherever", Sources.build(:memory, path: "wherever").path
    ensure
      Sources.send(:registry).delete(:memory)
    end

    test "an unknown source names the ones that are registered" do
      error = assert_raises(Sources::UnknownSource) { Sources.build(:carrier_pigeon, path: "x") }

      assert_includes error.message, "json_file"
    end

    test "registering without a builder is rejected" do
      assert_raises(ArgumentError) { Sources.register(:broken) }
    end
  end
end

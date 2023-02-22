require "test_helper"

class ConclusionTest < ActiveSupport::TestCase
  test "requires a name and at least one context" do
    conclusion = Conclusion.new
    assert_not conclusion.valid?
    assert_includes conclusion.errors.attribute_names, :name
    assert_includes conclusion.errors.attribute_names, :context
  end

  test "names are unique" do
    build_conclusion("loris", "tail")

    assert_not Conclusion.new(name: "loris", context: %w[nocturnal]).valid?
  end

  test "context round-trips as an array" do
    conclusion = build_conclusion("lemur", "tail", "long tail (> 2in)", "diurnal")

    assert_equal [ "tail", "long tail (> 2in)", "diurnal" ], conclusion.reload.context
  end
end

require "test_helper"

module Quiz
  class ConclusionMatcherTest < ActiveSupport::TestCase
    setup { import_questionnaire! }

    # Regression test for the original matcher, which recomputed its running
    # minimum inside the loop. The comparison it was left with was almost
    # always true, so the last conclusion in the table won every time: every
    # one of the six routes through data.json reported "lemur", and "loris"
    # was unreachable. This is the full truth table for the shipped
    # questionnaire.
    EXPECTED = {
      [ "tail", "long tail (> 2in)", "nocturnal" ]  => nil,
      [ "tail", "long tail (> 2in)", "diurnal" ]    => "lemur",
      [ "tail", "short tail (< 2in)", "nocturnal" ] => "loris",
      [ "tail", "short tail (< 2in)", "diurnal" ]   => nil,
      [ "no tail", "nocturnal" ]                    => "loris",
      [ "no tail", "diurnal" ]                      => nil
    }.freeze

    test "every route through the shipped questionnaire reaches the right conclusion" do
      EXPECTED.each do |contexts, expected|
        result = ConclusionMatcher.call(contexts)
        message = "#{contexts.inspect} should conclude #{expected.inspect}"
        if expected.nil?
          assert_nil result.conclusion, message
        else
          assert_equal expected, result.conclusion.name, message
        end
      end
    end

    test "the truth table covers every route the questionnaire can produce" do
      assert_equal EXPECTED.keys.sort, Quiz::Graph.current.context_paths.sort
    end

    test "not every route is answerable, and that is reported rather than guessed" do
      result = ConclusionMatcher.call([ "no tail", "diurnal" ])

      assert_not_predicate result, :conclusive?
      assert_nil result.conclusion
      assert_equal "lemur", result.best.conclusion.name
      assert_equal [ "no tail" ], result.best.unexplained
      assert_equal 50, result.best.percentage
    end

    test "a conclusion only has to accept the observed contexts, not use all of them" do
      # "loris" accepts both "tail" and "no tail"; observing only one of them
      # is still an exact match.
      result = ConclusionMatcher.call([ "no tail", "nocturnal" ])

      assert_predicate result, :conclusive?
      assert_equal "loris", result.conclusion.name
      assert_equal 100, result.best.percentage
    end

    test "ties break towards the more specific conclusion" do
      Conclusion.delete_all
      broad = build_conclusion("broad", "a", "b", "c", "d")
      narrow = build_conclusion("narrow", "a", "b")

      result = ConclusionMatcher.call(%w[a b])

      assert_equal narrow.name, result.conclusion.name
      assert_equal [ narrow.name, broad.name ], result.candidates.map { |c| c.conclusion.name }
    end

    test "no answers is never conclusive" do
      result = ConclusionMatcher.call([])

      assert_not_predicate result, :conclusive?
      assert_nil result.conclusion
      assert(result.candidates.all? { |candidate| candidate.percentage.zero? })
    end

    test "duplicate contexts do not inflate the score" do
      result = ConclusionMatcher.call([ "no tail", "no tail", "nocturnal" ])

      assert_equal [ "no tail", "nocturnal" ], result.observed
      assert_equal 100, result.best.percentage
    end

    test "candidates are ranked and every conclusion is accounted for" do
      result = ConclusionMatcher.call([ "tail", "short tail (< 2in)", "nocturnal" ])

      assert_equal Conclusion.count, result.candidates.size
      assert_equal result.candidates.map(&:score).sort.reverse, result.candidates.map(&:score)
      assert_equal 1, result.runners_up.size
    end
  end
end

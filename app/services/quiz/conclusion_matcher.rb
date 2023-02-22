module Quiz
  # Decides which conclusion a visitor's answers point at.
  #
  # A conclusion carries the set of contexts it *accepts* — "loris" accepts
  # both "tail" and "no tail" because lorises come both ways. A conclusion is
  # therefore an exact match when every context the visitor produced is one it
  # accepts; it does not have to account for all of them being present.
  #
  # When nothing matches exactly the questionnaire simply has no answer for
  # that route, and saying so is the correct behaviour. The ranked candidates
  # are still returned so the result page can show the closest fit rather than
  # a blank screen.
  class ConclusionMatcher
    Candidate = Struct.new(:conclusion, :score, :matched, :unexplained, keyword_init: true) do
      def exact?
        unexplained.empty?
      end

      def percentage
        (score * 100).round
      end
    end

    Result = Struct.new(:candidates, :observed, keyword_init: true) do
      def best
        candidates.first
      end

      def conclusive?
        observed.any? && best.present? && best.exact?
      end

      def conclusion
        conclusive? ? best.conclusion : nil
      end

      def runners_up
        candidates.drop(1)
      end
    end

    def self.call(observed_contexts, conclusions: nil)
      new(observed_contexts, conclusions: conclusions).call
    end

    def initialize(observed_contexts, conclusions: nil)
      @observed = Array(observed_contexts).map(&:to_s).uniq
      @conclusions = conclusions
    end

    def call
      ranked = conclusions.map { |conclusion| candidate_for(conclusion) }.sort_by do |candidate|
        # Highest score first; then the most specific conclusion (the one that
        # accepts the fewest contexts); then name, so ties are deterministic.
        [ -candidate.score, candidate.conclusion.context.size, candidate.conclusion.name.to_s ]
      end

      Result.new(candidates: ranked, observed: @observed)
    end

    private

    def conclusions
      @conclusions || Conclusion.ordered.to_a
    end

    def candidate_for(conclusion)
      accepted = conclusion.context.map(&:to_s)
      matched = @observed & accepted
      Candidate.new(
        conclusion: conclusion,
        score: @observed.empty? ? 0.0 : matched.size.fdiv(@observed.size),
        matched: matched,
        unexplained: @observed - accepted
      )
    end
  end
end

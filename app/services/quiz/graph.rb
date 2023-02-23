module Quiz
  # Read-only view over the persisted questionnaire, loaded in a single round
  # trip. Owning the traversal here keeps the controller, the views and the
  # tests from each re-deriving it (and from issuing one query per hop).
  class Graph
    class CyclicQuestionnaire < StandardError; end

    def self.current
      new(Question.ordered.includes(:answers).to_a)
    end

    def initialize(questions)
      @questions = questions
      @by_external_id = questions.index_by(&:external_id)
    end

    attr_reader :questions

    def root
      @questions.first
    end

    def find(external_id)
      external_id.present? ? @by_external_id[external_id.to_s] : root
    end

    def size
      @questions.size
    end

    # Number of questions on the longest route from the root to a leaf, i.e.
    # the worst case number of answers a visitor has to give.
    def longest_path
      root ? depth_from(root, []) : 0
    end

    # Every root-to-leaf route as an ordered list of answer contexts. Used by
    # the import sanity check and by the test suite to assert the matcher over
    # the whole questionnaire rather than a hand-picked path.
    def context_paths
      return [] unless root

      paths_from(root, [], [])
    end

    # External ids referenced as a "next question" but never imported.
    def dangling_references
      @questions.flat_map { |q| q.answers.reject(&:terminal?).map(&:next_question_external_id) }
                .uniq
                .reject { |id| @by_external_id.key?(id) }
    end

    private

    def depth_from(question, trail)
      raise CyclicQuestionnaire, "cycle through #{question.external_id}" if trail.include?(question.external_id)

      onward = question.answers.reject(&:terminal?)
                       .filter_map { |a| @by_external_id[a.next_question_external_id] }
      return 1 if onward.empty?

      1 + onward.map { |q| depth_from(q, trail + [ question.external_id ]) }.max
    end

    def paths_from(question, contexts, trail)
      raise CyclicQuestionnaire, "cycle through #{question.external_id}" if trail.include?(question.external_id)

      question.answers.flat_map do |answer|
        walked = contexts + [ answer.context ]
        following = answer.terminal? ? nil : @by_external_id[answer.next_question_external_id]
        following ? paths_from(following, walked, trail + [ question.external_id ]) : [ walked ]
      end
    end
  end
end

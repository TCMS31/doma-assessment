module Quiz
  # A visitor's run through the questionnaire, backed by the Rails session.
  #
  # Steps are stored as plain string-keyed hashes because the session is
  # serialised as JSON; anything richer would come back as a different type on
  # the next request.
  class Progress
    KEY = "quiz_progress".freeze

    def initialize(session)
      @session = session
      @session[KEY] = [] unless @session[KEY].is_a?(Array)
    end

    def steps
      @session[KEY]
    end

    # Records an answer. Re-answering a question the visitor has already passed
    # (browser back button, or a shared link) discards everything after it,
    # because in a decision tree those later answers are no longer reachable.
    def record(question, answer)
      step = {
        "question_external_id" => question.external_id,
        "statement" => question.statement,
        "answer_type" => answer.answer_type,
        "context" => answer.context
      }

      index = steps.index { |s| s["question_external_id"] == question.external_id }
      index ? steps[index..] = [ step ] : steps << step
      @session[KEY] = steps
      self
    end

    def contexts
      steps.map { |step| step["context"] }
    end

    def answered_count
      steps.size
    end

    def started?
      steps.any?
    end

    def reset!
      @session[KEY] = []
      self
    end
  end
end

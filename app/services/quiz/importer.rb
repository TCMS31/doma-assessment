module Quiz
  # Loads a questionnaire from a source into the database.
  #
  # This used to run as a before_action on every question page view, which
  # meant a file read, a JSON parse and one SELECT per question and per
  # conclusion on the hot path. It is a deploy-time concern, so it lives in
  # `bin/rails quiz:import` (and db/seeds.rb) instead.
  #
  # Importing is idempotent: running it twice leaves the same rows, and editing
  # the source updates them in place rather than duplicating.
  class Importer
    class InvalidQuestionnaire < StandardError; end

    Report = Struct.new(:questions, :answers, :conclusions, :source, keyword_init: true) do
      def to_s
        "imported #{questions} question(s), #{answers} answer(s), " \
          "#{conclusions} conclusion(s) from #{source}"
      end
    end

    def self.call(source: nil)
      new(source: source).call
    end

    def initialize(source: nil)
      @source = source || Quiz::Sources.default
    end

    def call
      report = nil

      ApplicationRecord.transaction do
        questions = @source.questions
        conclusions = @source.conclusions
        raise InvalidQuestionnaire, "questionnaire contains no questions" if questions.empty?

        answer_count = import_questions(questions)
        import_conclusions(conclusions)
        prune(questions, conclusions)
        verify!

        report = Report.new(
          questions: questions.size,
          answers: answer_count,
          conclusions: conclusions.size,
          source: @source.try(:description) || @source.class.name
        )
      end

      report
    end

    private

    def import_questions(questions)
      questions.sum do |attrs|
        question = Question.find_or_initialize_by(external_id: attrs[:external_id])
        question.statement = attrs[:statement]
        question.save!
        import_answers(question, attrs[:answers])
      end
    end

    def import_answers(question, answers)
      raise InvalidQuestionnaire, "question #{question.external_id} has no answers" if answers.blank?

      answers.each do |attrs|
        answer = question.answers.find_or_initialize_by(answer_type: attrs[:answer_type])
        answer.context = attrs[:context]
        answer.next_question_external_id = attrs[:next_question_external_id]
        answer.save!
      end
      question.answers.where.not(answer_type: answers.map { |a| a[:answer_type] }).delete_all
      answers.size
    end

    def import_conclusions(conclusions)
      conclusions.each do |attrs|
        conclusion = Conclusion.find_or_initialize_by(name: attrs[:name])
        conclusion.context = attrs[:context]
        conclusion.save!
      end
    end

    # Rows whose source entry has gone away would otherwise linger and skew
    # matching, so a re-import is a full reconciliation rather than an upsert.
    def prune(questions, conclusions)
      Question.where.not(external_id: questions.map { |q| q[:external_id] }).destroy_all
      Conclusion.where.not(name: conclusions.map { |c| c[:name] }).delete_all
    end

    def verify!
      dangling = Quiz::Graph.current.dangling_references
      return if dangling.empty?

      raise InvalidQuestionnaire, "answers point at unknown questions: #{dangling.join(', ')}"
    end
  end
end

class QuestionsController < ApplicationController
  before_action :load_progress
  before_action :load_graph, only: %i[index submit_answer]

  # GET /questions[?question=q2]
  def index
    @question = @graph.find(params[:question])
    return redirect_to(root_path, alert: t(".unknown_question")) if @question.nil?

    # Landing on the first question is how a visitor starts over.
    @progress.reset! if @question == @graph.root
    @step_number = @progress.answered_count + 1
    @total_steps = @graph.longest_path
  end

  # POST /questions/submit_answer
  def submit_answer
    question = @graph.find(params[:question])
    answer = question&.answers&.detect { |a| a.answer_type == params[:answer] }
    return redirect_to(questions_path, alert: t(".unknown_answer")) if answer.nil?

    @progress.record(question, answer)

    if answer.terminal?
      redirect_to result_questions_path
    else
      redirect_to questions_path(question: answer.next_question_external_id)
    end
  end

  # GET /questions/result
  def result
    return redirect_to(questions_path) unless @progress.started?

    @steps = @progress.steps
    @match = Quiz::ConclusionMatcher.call(@progress.contexts)
  end

  private

  def load_progress
    @progress = Quiz::Progress.new(session)
  end

  def load_graph
    @graph = Quiz::Graph.current
    redirect_to root_path, alert: t("questions.empty_questionnaire") if @graph.root.nil?
  end
end

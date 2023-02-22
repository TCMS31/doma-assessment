class ApplicationController < ActionController::Base
  # The questionnaire has to be imported before anything can be answered;
  # surfacing that as a clear page beats a NoMethodError on nil.
  rescue_from ActiveRecord::StatementInvalid, with: :questionnaire_unavailable

  private

  def questionnaire_unavailable(error)
    raise error unless error.message.match?(/relation .* does not exist/i)

    render plain: "The questionnaire database has not been migrated. Run `bin/rails db:prepare quiz:import`.",
           status: :service_unavailable
  end
end

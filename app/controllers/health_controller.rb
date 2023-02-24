# Liveness/readiness probe for the container healthcheck and any load balancer
# in front of it. It touches the database, because an app that cannot reach
# Postgres cannot serve a question.
class HealthController < ApplicationController
  def show
    ActiveRecord::Base.connection.select_value("SELECT 1")
    render json: { status: "ok", questions: Question.count }
  rescue StandardError => e
    render json: { status: "error", error: e.class.name }, status: :service_unavailable
  end
end

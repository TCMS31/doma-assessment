class HomepageController < ApplicationController
  def index
    @question_count = Question.count
    @conclusion_count = Conclusion.count
  end
end

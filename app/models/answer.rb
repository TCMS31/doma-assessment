class Answer < ApplicationRecord
  belongs_to :question, inverse_of: :answers

  validates :answer_type, presence: true, uniqueness: { scope: :question_id }
  validates :context, presence: true

  # An answer with nothing to follow ends the run.
  def terminal?
    next_question_external_id.blank?
  end

  def label
    answer_type.to_s.humanize
  end
end

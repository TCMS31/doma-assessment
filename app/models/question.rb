class Question < ApplicationRecord
  has_many :answers, -> { order(:id) }, dependent: :destroy, inverse_of: :question

  validates :external_id, presence: true, uniqueness: true
  validates :statement, presence: true

  scope :ordered, -> { order(:id) }

  # The questionnaire is walked from the first imported question; the source
  # document's ordering is the author's ordering.
  def self.root
    ordered.first
  end

  def to_param
    external_id
  end
end

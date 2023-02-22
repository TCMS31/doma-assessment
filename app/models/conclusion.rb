class Conclusion < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :context, presence: true

  scope :ordered, -> { order(:id) }

  def to_s
    name
  end
end

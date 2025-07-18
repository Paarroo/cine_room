class Movie < ApplicationRecord
  belongs_to :user
  belongs_to :validated_by, class_name: 'User', optional: true
  has_many :events, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :title, :synopsis, :director, :duration, :genre, :year, presence: true
  validates :duration, numericality: { greater_than: 0, less_than: 300 }
  validates :year, numericality: {
    greater_than: 1900,
    less_than_or_equal_to: Date.current.year + 2
  }

  enum :validation_status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  scope :approved, -> { where(validation_status: :approved) }
end

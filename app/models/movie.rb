class Movie < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :title, :synopsis, :director, :duration, :genre, :year, presence: true
  validates :duration, numericality: { greater_than: 0 }
  validates :year, numericality: { greater_than: 1900, less_than_or_equal_to: Date.current.year + 2 }
end

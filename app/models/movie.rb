class Movie < ApplicationRecord
  belongs_to :creator
  has_many :events, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :title, :synopsis, :director, :duration, :genre, :year, presence: true
  validates :duration, numericality: { greater_than: 0, less_than: 300 }
  validates :year, numericality: {
    greater_than: 1900,
    less_than_or_equal_to: Date.current.year + 2
  }

  VALIDATION_STATUSES = %w[pending approved rejected].freeze

  validates :validation_status, inclusion: { in: VALIDATION_STATUSES }

  after_initialize :set_default_validation_status, if: :new_record?

  def pending?
    validation_status == 'pending'
  end

  def approved?
    validation_status == 'approved'
  end

  def rejected?
    validation_status == 'rejected'
  end

  private

  def set_default_validation_status
    self.validation_status ||= 'pending'
  end
end

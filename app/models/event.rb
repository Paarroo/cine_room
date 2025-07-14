class Event < ApplicationRecord
  belongs_to :movie
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
  has_many :reviews, dependent: :destroy

  validates :title, :venue_name, :venue_address, :event_date, :start_time, :max_capacity, :price_cents, presence: true
  validates :max_capacity, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :event_date, presence: true

  STATUSES = %w[upcoming sold_out completed cancelled].freeze

  validates :status, inclusion: { in: STATUSES }

  after_initialize :set_default_status, if: :new_record?
  before_save :update_status_if_sold_out

  def available_spots
    max_capacity - participations.where(status: 'confirmed').count
  end

  def sold_out?
    available_spots <= 0
  end

  def upcoming?
    status == 'upcoming'
  end

  def completed?
    status == 'completed'
  end

  def cancelled?
    status == 'cancelled'
  end

  private

  def set_default_status
    self.status ||= 'upcoming'
  end

  def update_status_if_sold_out
    self.status = 'sold_out' if sold_out? && upcoming?
  end
end

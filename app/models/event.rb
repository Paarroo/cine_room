class Event < ApplicationRecord
  belongs_to :movie
  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :users, through: :participations

  validates :title, :venue_name, :venue_address, :event_date, :start_time,
              :max_capacity, :price_cents, presence: true
    validates :max_capacity, numericality: { greater_than: 0 }
    validates :price_cents, numericality: { greater_than: 0 }
    validates :status, inclusion: { in: %w[upcoming sold_out completed cancelled] }

    scope :upcoming, -> { where(status: 'upcoming') }
    scope :sold_out, -> { where(status: 'sold_out') }
    scope :completed, -> { where(status: 'completed') }
    scope :cancelled, -> { where(status: 'cancelled') }

  def available_spots
    max_capacity - participations.confirmed.count
  end

  def sold_out?
    available_spots <= 0
  end

  def price_euros
    price_cents / 100.0
  end
end

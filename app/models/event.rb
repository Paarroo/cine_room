class Event < ApplicationRecord
  belongs_to :movie
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
  has_many :reviews, dependent: :destroy

  validates :title, :venue_name, :venue_address, :event_date, :start_time, :max_capacity, :price_cents, presence: true
  validates :max_capacity, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :event_date, presence: true

  def available_spots
    max_capacity - participations.where(status: 'confirmed').count
  end

  def sold_out?
    available_spots <= 0
  end
end

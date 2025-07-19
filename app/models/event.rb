class Event < ApplicationRecord
  belongs_to :movie
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
  has_many :reviews, dependent: :destroy

  validates :title, :venue_name, :venue_address, :event_date, :start_time, :max_capacity, :price_cents, presence: true
  validates :max_capacity, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :price_cents, numericality: { greater_than: 0 }

  enum :status, { upcoming: 0, sold_out: 1, completed: 2, cancelled: 3 }, default: :upcoming

  before_save :update_status_if_sold_out


  scope :by_title, ->(q) {
    joins(:movie).where("movies.title ILIKE ?", "%#{q}%") if q.present?
  }

  scope :by_genre, ->(genre) {
    joins(:movie).where(movies: { genre: genre }) if genre.present?
  }

  scope :by_venue, ->(venue) {
    where(venue_name: venue) if venue.present?
  }

  scope :by_date_filter, ->(filter) {
    case filter
    when "week"
      where(event_date: Date.today..Date.today.end_of_week)
    when "month"
      where(event_date: Date.today..Date.today.end_of_month)
    else
      all
    end
  }

  def self.filter_by(params)
    by_title(params[:q])
      .by_genre(params[:genre])
      .by_venue(params[:venue])
      .by_date_filter(params[:date_filter])
  end


  def available_spots
  reserved_seats = participations.where(status: 'confirmed').sum(:seats)
  max_capacity - reserved_seats
  end

  def sold_out?
    available_spots <= 0
  end

  private

  def update_status_if_sold_out
    self.status = 'sold_out' if sold_out? && upcoming?
  end

  scope :upcoming, -> { where(status: :upcoming) }
end

class Event < ApplicationRecord
  before_save :auto_set_finished_status
  before_save :update_status_if_sold_out

  belongs_to :movie
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
  has_many :reviews, dependent: :destroy

  # Geocoding for venue address
  geocoded_by :venue_address
  after_validation :geocode, if: :should_geocode?
  
  before_save :ensure_geocoded_coordinates

  validates :title, :venue_name, :venue_address, :event_date, :start_time, :max_capacity, :price_cents, presence: true
  validates :max_capacity, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :price_cents, numericality: { greater_than: 0 }
  validate :event_date_must_be_at_least_one_week_from_now

  
  enum :status, { upcoming: 0, sold_out: 1, ongoing: 2, finished: 3, cancelled: 4 }, default: :upcoming

  

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
    upcoming
      .by_title(params[:q])
      .by_genre(params[:genre])
      .by_venue(params[:venue])
      .by_date_filter(params[:date_filter])
  end

  def self.update_finished_events
    where("event_date < ?", Time.current).where.not(status: :finished).update_all(status: :finished)
  end

  def event_date_must_be_at_least_one_week_from_now
    if event_date < 1.week.from_now
      errors.add(:event_date, "doit être au moins une semaine après aujourd’hui")
    end
  end


  def available_spots
    reserved_seats = participations.where(status: 'confirmed').sum(:seats)
    max_capacity - reserved_seats
  end

  def sold_out?
    available_spots <= 0
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "title", "description", "venue_name", "venue_address",
      "event_date", "start_time", "max_capacity", "price_cents",
      "status", "latitude", "longitude", "created_at", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "movie", "participations", "users", "reviews" ]
  end

  private

  def should_geocode?
    venue_address_changed? || (latitude.blank? || longitude.blank?)
  end

  def ensure_geocoded_coordinates
    if venue_address.present? && (latitude.blank? || longitude.blank?)
      geocode
      
      # If geocoding fails, set default coordinates for Paris
      if latitude.blank? || longitude.blank?
        Rails.logger.warn "Geocoding failed for event #{id}: #{venue_address}. Using Paris coordinates."
        self.latitude = 48.8566
        self.longitude = 2.3522
      end
    end
  end

  def update_status_if_sold_out
    self.status = 'sold_out' if sold_out? && upcoming?
  end

  def auto_set_finished_status
    if event_date.present? && event_date < Time.current
      self.status = "finished"
    end
  end

  scope :upcoming, -> { where(status: :upcoming) }
end

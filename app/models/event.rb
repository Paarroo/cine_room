class Event < ApplicationRecord
  before_save :auto_set_finished_status
  before_save :update_status_if_sold_out
  after_create_commit :attach_default_image

  belongs_to :movie
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
  has_many :reviews, dependent: :destroy
  has_one_attached :image

  # Geocoding for venue address
  geocoded_by :venue_address
  after_validation :geocode, if: :should_geocode?
  
  before_save :ensure_geocoded_coordinates

  validates :title, :venue_name, :venue_address, :event_date, :start_time, :max_capacity, :price_cents, presence: true
  validates :max_capacity, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :latitude, :longitude, presence: true, numericality: true
  validates :latitude, numericality: { in: -90..90 }
  validates :longitude, numericality: { in: -180..180 }
  validate :event_date_must_be_at_least_one_week_from_now
  validate :coordinates_are_reasonable

  
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

  def attach_default_image
    return if image.attached?

    default_image_path = Rails.root.join("app/assets/images/default-event.jpg")
    
    # Skip attachment if file doesn't exist (e.g., on Heroku during seed)
    return unless File.exist?(default_image_path)

    begin
      image.attach(
        io: File.open(default_image_path),
        filename: "default-event.jpg",
        content_type: "image/jpeg"
      )
    rescue => e
      Rails.logger.warn "Could not attach default image: #{e.message}"
    end
  end

  def should_geocode?
    venue_address_changed? || (latitude.blank? || longitude.blank?)
  end

  def ensure_geocoded_coordinates
    if venue_address.present? && (latitude.blank? || longitude.blank?)
      Rails.logger.info "🌍 Starting geocoding for event #{id || 'new'}: '#{venue_address}'"
      
      begin
        # Test geocoding service availability first
        test_result = Geocoder.search("Paris, France").first
        if test_result.nil?
          Rails.logger.error "🚨 Geocoding service unavailable - test query failed"
          self.latitude = 48.8566
          self.longitude = 2.3522
          self.geocoding_status = "service_unavailable"
          return
        end
        
        # Retry geocoding with better error handling
        Rails.logger.info "🔍 Geocoding address: #{venue_address}"
        geocode
        
        # If geocoding fails, set default coordinates for Paris
        if latitude.blank? || longitude.blank?
          Rails.logger.warn "❌ Geocoding failed for event #{id || 'new'}: #{venue_address}. Using Paris coordinates."
          Rails.logger.warn "📊 Geocoder lookup: #{Geocoder.config.lookup}, timeout: #{Geocoder.config.timeout}"
          self.latitude = 48.8566
          self.longitude = 2.3522
          self.geocoding_status = "failed"
        else
          Rails.logger.info "✅ Successfully geocoded event #{id || 'new'}: #{venue_address} -> #{latitude}, #{longitude}"
          self.geocoding_status = "success"
        end
      rescue Geocoder::Error => e
        Rails.logger.error "🚨 Geocoding error for event #{id || 'new'}: #{e.class} - #{e.message}. Using Paris coordinates."
        Rails.logger.error "🔧 Geocoder config: lookup=#{Geocoder.config.lookup}, timeout=#{Geocoder.config.timeout}, use_https=#{Geocoder.config.use_https}"
        self.latitude = 48.8566
        self.longitude = 2.3522
        self.geocoding_status = "error"
      rescue => e
        Rails.logger.error "💥 Unexpected geocoding error for event #{id || 'new'}: #{e.class} - #{e.message}. Using Paris coordinates."
        Rails.logger.error "📍 Address was: #{venue_address}"
        Rails.logger.error "🔍 Backtrace: #{e.backtrace.first(3).join(', ')}"
        self.latitude = 48.8566
        self.longitude = 2.3522
        self.geocoding_status = "unexpected_error"
      end
    elsif latitude.present? && longitude.present?
      self.geocoding_status = "existing_coordinates"
      Rails.logger.info "📍 Event #{id || 'new'} already has coordinates: #{latitude}, #{longitude}"
    end
  end

  def coordinates_are_reasonable
    return unless latitude.present? && longitude.present?
    
    # Check if coordinates are in France (roughly)
    # France bounds: lat 41-51, lng -5 to 10
    unless latitude.between?(40, 52) && longitude.between?(-6, 11)
      Rails.logger.warn "Event #{id || 'new'} has suspicious coordinates: #{latitude}, #{longitude} for address: #{venue_address}"
      # Don't fail validation, just log warning - coordinates might be valid for international events
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
  scope :with_default_coordinates, -> { where(latitude: 48.8566, longitude: 2.3522) }
  scope :geocoding_failed, -> { where(geocoding_status: ['failed', 'error', 'service_unavailable', 'unexpected_error']) }

  # Dashboard metrics methods
  def self.events_status_chart_data
    if count == 0
      return generate_sample_events_data
    end

    group(:status).count.map do |status, count|
      total = Event.count
      {
        status: status.humanize,
        count: count,
        percentage: total.zero? ? 0 : ((count.to_f / total) * 100).round(1)
      }
    end
  end

  def self.quick_stats
    {
      upcoming_events: where(status: :upcoming).count,
      total_events: count
    }
  end

  private

  def self.generate_sample_events_data
    [
      { status: "Upcoming", count: 8, percentage: 40.0 },
      { status: "Ongoing", count: 3, percentage: 15.0 },
      { status: "Finished", count: 7, percentage: 35.0 },
      { status: "Cancelled", count: 2, percentage: 10.0 }
    ]
  end
end

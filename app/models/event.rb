class Event < ApplicationRecord
  before_save :auto_set_finished_status
  before_save :update_status_if_sold_out
  after_create_commit :attach_default_image

  # Common countries for cinema events
  COUNTRIES = [
    ['France', 'France'],
    ['United States', 'United States'],
    ['Canada', 'Canada'],
    ['United Kingdom', 'United Kingdom'],
    ['Germany', 'Germany'],
    ['Spain', 'Spain'],
    ['Italy', 'Italy'],
    ['Belgium', 'Belgium'],
    ['Switzerland', 'Switzerland'],
    ['Japan', 'Japan'],
    ['Australia', 'Australia'],
    ['New Zealand', 'New Zealand'],
    ['Brazil', 'Brazil'],
    ['Argentina', 'Argentina'],
    ['Mexico', 'Mexico'],
    ['Other', 'Other']
  ].freeze

  belongs_to :movie
  has_many :participations, dependent: :destroy
  has_many :users, through: :participations
  has_many :reviews, dependent: :destroy
  has_one_attached :image

  # Geocoding for venue address with country context
  geocoded_by :full_address
  after_validation :geocode, if: :should_geocode?
  
  before_save :ensure_geocoded_coordinates

  validates :title, :venue_name, :venue_address, :event_date, :start_time, :max_capacity, :price_cents, presence: true
  validates :country, presence: { message: "doit être spécifié pour améliorer le géocodage" }
  validates :max_capacity, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :latitude, :longitude, presence: { message: "sont requises. Vérifiez que l'adresse peut être géocodée." }, numericality: true
  validates :latitude, numericality: { in: -90..90, message: "doit être entre -90 et 90 degrés" }
  validates :longitude, numericality: { in: -180..180, message: "doit être entre -180 et 180 degrés" }
  validate :event_date_must_be_at_least_one_week_from_now
  validate :coordinates_are_reasonable
  validate :venue_address_format

  
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
    # Skip validation during seeding
    return if Rails.application.config.seed_in_progress
    
    if event_date < 1.week.from_now
      errors.add(:event_date, "doit être au moins une semaine après aujourd'hui")
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
      "title", "description", "venue_name", "venue_address", "country",
      "event_date", "start_time", "max_capacity", "price_cents",
      "status", "latitude", "longitude", "geocoding_status", "geocoding_confidence",
      "coordinates_verified", "created_at", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "movie", "participations", "users", "reviews" ]
  end

  # Business logic methods - moved from controllers
  
  # Get analytics service for this event
  def analytics
    @analytics ||= EventAnalyticsService.new(self)
  end

  # Get export service for this event
  def export_service
    @export_service ||= EventExportService.new(self)
  end

  # Calculate revenue using service
  def calculate_revenue
    analytics.calculate_revenue
  end

  # Get booking analytics
  def booking_analytics
    analytics.calculate_booking_analytics
  end

  # Get capacity metrics
  def capacity_metrics
    analytics.calculate_capacity_metrics
  end

  # Get recent activities
  def recent_activities(limit: 5)
    analytics.get_recent_activities(limit: limit)
  end

  # Complete event with proper status management
  def complete!
    update!(status: :completed, updated_at: Time.current)
  end

  # Cancel event and handle participations
  def cancel!
    transaction do
      update!(status: :cancelled, updated_at: Time.current)
      participations.where(status: :pending).update_all(status: :cancelled)
    end
  end

  # Reopen cancelled event
  def reopen!
    update!(status: :upcoming, updated_at: Time.current)
  end

  # Check if event can be cancelled
  def can_be_cancelled?
    upcoming? && event_date > 1.day.from_now
  end

  # Check if event can be completed
  def can_be_completed?
    upcoming? && event_date < Time.current
  end

  # Get confirmed participations
  def confirmed_participations
    participations.where(status: [:confirmed, :attended])
  end

  # Calculate occupancy rate
  def occupancy_rate
    return 0 if max_capacity.zero?
    
    confirmed_seats = confirmed_participations.sum(:seats)
    (confirmed_seats.to_f / max_capacity * 100).round(1)
  end

  # Check if event is nearly sold out (>90% capacity)
  def nearly_sold_out?
    occupancy_rate >= 90
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

  # Create full address with country context for better geocoding
  def full_address
    return venue_address unless country.present?
    "#{venue_address}, #{country}"
  end

  def should_geocode?
    venue_address_changed? || country_changed? || (latitude.blank? || longitude.blank?)
  end

  def ensure_geocoded_coordinates
    if venue_address.present? && (latitude.blank? || longitude.blank?)
      # Use OpenCage geocoding service for much better accuracy
      geocoding_service = OpenCageGeocodingService.new(
        address: venue_address,
        country: country,
        venue_name: venue_name
      )
      
      result = geocoding_service.geocode_with_quality_control
      
      if result[:success]
        self.latitude = result[:latitude]
        self.longitude = result[:longitude]
        self.geocoding_confidence = result[:confidence]
        self.coordinates_verified = result[:verified] || false
        self.geocoding_status = "success"
        
        Rails.logger.info "✅ OpenCage geocoding succeeded for event #{id || 'new'}: #{result[:formatted_address]} -> #{latitude}, #{longitude} (confidence: #{geocoding_confidence}%)"
        
        # Add warnings to errors if verification failed (but don't prevent saving)
        if result[:warnings]&.any?
          result[:warnings].each do |warning|
            Rails.logger.warn "⚠️  #{warning} for event #{id || 'new'}"
          end
        end
      else
        self.geocoding_status = "failed"
        Rails.logger.error "❌ OpenCage geocoding failed for event #{id || 'new'}: #{result[:error]}"
        
        # Add helpful error message with suggestions
        error_message = "Geocoding failed: #{result[:error]}"
        if result[:suggestions]&.any?
          error_message += ". Suggestions: #{result[:suggestions].join(', ')}"
        end
        errors.add(:venue_address, error_message)
      end
    elsif latitude.present? && longitude.present?
      self.geocoding_status = "existing_coordinates"
      Rails.logger.info "📍 Event #{id || 'new'} already has coordinates: #{latitude}, #{longitude}"
    end
  end

  def coordinates_are_reasonable
    return unless latitude.present? && longitude.present?
    
    # Basic sanity check for valid coordinates (worldwide)
    if latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180
      errors.add(:latitude, "must be between -90 and 90") if latitude < -90 || latitude > 90
      errors.add(:longitude, "must be between -180 and 180") if longitude < -180 || longitude > 180
      Rails.logger.error "Event #{id || 'new'} has invalid coordinates: #{latitude}, #{longitude}"
    end
    
    # Log extreme coordinates for manual review (but don't fail validation)
    if latitude.abs > 85 || longitude.abs > 175
      Rails.logger.warn "Event #{id || 'new'} has extreme coordinates: #{latitude}, #{longitude} for address: #{venue_address}"
    end
  end
  
  def venue_address_format
    return unless venue_address.present?
    
    # Basic validation for international address format - must have some structure
    if venue_address.length < 10
      errors.add(:venue_address, "doit être plus détaillée pour un géocodage précis")
    end
    
    # Recommend including city and country for better geocoding
    unless venue_address.match?(/,.*\w/i)  # At least one comma separator
      Rails.logger.warn "Event #{id || 'new'} address might benefit from city/country: #{venue_address}"
    end
    
    # Warn about detailed address parts that might affect geocoding
    if venue_address.match?(/apt\.|suite|floor|étage|villa|résidence|building|bloc/i)
      Rails.logger.info "Event #{id || 'new'} has detailed address that might affect geocoding: #{venue_address}"
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

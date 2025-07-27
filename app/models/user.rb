class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable, :confirmable


  before_create :skip_confirmation_for_admin
  after_create :send_welcome_email, unless: -> { Rails.env.production? }
  after_commit :attach_default_avatar, on: [:create]
  after_update :sync_director_name_to_movies, if: :saved_change_to_name?

  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :events, through: :participations
  has_many :movies
  has_many :created_events, through: :movies, source: :events
  has_many :favorites, dependent: :destroy
  has_many :favorite_movies, through: :favorites, source: :movie
  has_one_attached :avatar

  validate :name_cannot_be_changed_after_publishing, on: :update
  validates :email, format: { with: /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/, message: "doit être une adresse email valide" }
  validate :validate_email_domain, on: [:create, :update]

  enum :role, { user: 0, creator: 1, admin: 2 }, default: :user
  scope :admin_users, -> { where(role: :admin) }
  scope :regular_users, -> { where(role: :user) }
  scope :creators, -> { where(role: :creator) }
  scope :movie_creators, -> { joins(:movies).distinct }

  def full_name
    "#{first_name} #{last_name}"
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "email", "first_name", "last_name", "role", "bio",
      "created_at", "updated_at", "sign_in_count", "current_sign_in_at",
      "last_sign_in_at", "current_sign_in_ip", "last_sign_in_ip"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "participations", "reviews", "events", "movies", "created_events" ]
  end

  private

  def attach_default_avatar
    return if avatar.attached?
    
    # Skip avatar attachment completely in production to avoid file access issues
    return if Rails.env.production?
    
    begin
      # Only attach default avatar in development/test environments
      avatar.attach(
        io: File.open(Rails.root.join("app", "assets", "images", "default-avatar.jpg")),
        filename: "default-avatar.jpg",
        content_type: "image/jpeg"
      )
      
      # Skip ActiveStorage analysis to avoid job queue issues
      avatar.blob.update!(metadata: { analyzed: true }) if avatar.attached?
      
    rescue Errno::ENOENT, ActiveStorage::IntegrityError, StandardError => e
      Rails.logger.warn "Avatar attachment failed: #{e.message}"
    end
  end

  def name_cannot_be_changed_after_publishing
    return unless movies.exists?

    if first_name_changed? || last_name_changed?
      errors.add(:base, "Impossible de modifier votre nom après publication d’un film approuvé.")
    end
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_now
  end

  def saved_change_to_name?
    saved_change_to_first_name? || saved_change_to_last_name?
  end

  def sync_director_name_to_movies
    movies.update_all(director: full_name)
  end

  def skip_confirmation_for_admin
    if admin?
      skip_confirmation!
    end
  end

  def validate_email_domain
    return unless email.present? && email.include?('@')
    
    domain = email.split('@').last
    blocked_domains = %w[fake.com example.org invalid.email nonexistent.domain]
    
    # Allow .test domains in development/test environments
    blocked_domains << 'test.com' unless Rails.env.development? || Rails.env.test?
    
    if blocked_domains.include?(domain.downcase)
      errors.add(:email, "utilise un domaine email non valide")
    end
    
    # Basic domain format validation - allow .test in dev/test
    domain_pattern = if Rails.env.development? || Rails.env.test?
      /\A[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
    else
      /\A[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/
    end
    
    unless domain.match?(domain_pattern)
      errors.add(:email, "doit utiliser un domaine valide")
    end
  end
end

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable, :confirmable


  before_create :skip_confirmation_for_admin
  after_create :send_welcome_email, unless: -> { Rails.env.production? }
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
  validate :avatar_format
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

  def avatar_url
    if avatar.attached?
      avatar
    else
      # Return default avatar URL from Cloudinary
      "https://res.cloudinary.com/dhusbkszr/image/upload/v1753621019/ocuvyd737vat2fwwl76t0oyrbds7.png"
    end
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

  # Dashboard metrics methods
  def self.export_data
    select(:id, :email, :first_name, :last_name, :role, :created_at)
      .limit(1000)
      .map(&:attributes)
  end

  def self.quick_stats
    {
      total_users: count,
      admin_count: where(role: :admin).count,
      creator_count: where(role: :creator).count,
      user_count: where(role: :user).count
    }
  end

  private

  def attach_default_avatar
    # Disable default avatar attachment to avoid registration errors
    # Users can upload their own avatar after registration
    return
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

  def avatar_format
    return unless avatar.attached?

    # Check file type
    unless avatar.content_type.in?(['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
      errors.add(:avatar, 'doit être un fichier JPEG, PNG, GIF ou WebP')
    end

    # Check file size (max 5MB)
    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, 'doit faire moins de 5MB')
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

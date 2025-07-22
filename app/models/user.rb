class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable


  after_create :send_welcome_email
  after_update :sync_director_name_to_movies, if: :saved_change_to_name?

  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :events, through: :participations
  has_many :movies
  has_many :created_events, through: :movies, source: :events

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

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  end

  def saved_change_to_name?
    saved_change_to_first_name? || saved_change_to_last_name?
  end

  def sync_director_name_to_movies
    movies.update_all(director: full_name)
  end
end

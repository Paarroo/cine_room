class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :send_welcome_email

  has_one :creator, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :events, through: :participations
  has_many :movies, dependent: :destroy

  has_many :validated_movies, class_name: 'Movie', foreign_key: 'validated_by_id'

  enum :role, { user: 0, creator: 1, admin: 2 }, default: :user

  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    full_name.present? ? full_name : email
  end

  def can_access_admin?
    admin?
  end

  private

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  end
end

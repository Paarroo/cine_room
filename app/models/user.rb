class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :send_welcome_email

  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :events, through: :participations
  has_many :movies
  has_many :created_events, through: :movies, source: :events

  enum :role, { user: 0, creator: 1, admin: 2 }, default: :user

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  end
end

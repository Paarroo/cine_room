class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { user: 0, admin: 1 }, default: :user

  has_many :movies, dependent: :destroy
  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :events, through: :participations

  validates :first_name, :last_name, presence: true
  validates :role, presence: true

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def creator?
    movies.exists?
  end

  def validator?
    admin? && Movie.where(validated_by: self).exists?
  end

  scope :creators, -> { joins(:movies).distinct }

  scope :active_participants, -> { joins(:participations).where(participations: { status: :confirmed }).distinct }
end

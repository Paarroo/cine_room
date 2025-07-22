class Movie < ApplicationRecord
  attr_accessor :authorship_confirmed

  belongs_to :user
  belongs_to :validated_by, class_name: 'User', optional: true
  has_many :events, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :title, :synopsis, :director, :duration, :genre, :year, presence: true
  validates :duration, numericality: { greater_than: 0, less_than: 300 }
  validates :year, numericality: {
    greater_than: 1900,
    less_than_or_equal_to: Date.current.year
  }
  validate :authorship_must_be_confirmed, on: :create

  enum :validation_status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  scope :approved, -> { where(validation_status: :approved) }

  scope :by_title, ->(title) {
    where("title ILIKE ?", "%#{title.strip}%") if title.present?
  }

  scope :by_genre, ->(genre) {
    where(genre: genre) if genre.present?
  }

  scope :by_year, ->(year) {
    where(year: year) if year.present?
  }

  scope :by_director, ->(director) {
    where(director: director) if director.present?
  }

   # Combined filters
  def self.filter_by(params)
    approved
      .by_title(params[:q])
      .by_genre(params[:genre])
      .by_year(params[:year])
      .by_director(params[:director])
      .order(created_at: :desc)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[title synopsis director duration genre language year validation_status]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[reviews events]
  end

  private

  def authorship_must_be_confirmed
    if authorship_confirmed != "1"
      errors.add(:base, "Tu dois confirmer être l’auteur ou l’autrice de cette vidéo pour pouvoir la publier.")
    end
  end
end

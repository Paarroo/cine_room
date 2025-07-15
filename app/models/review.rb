class Review < ApplicationRecord
  belongs_to :user
  belongs_to :movie
  belongs_to :event

  validates :rating, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: [ :movie_id, :event_id ], message: "You already reviewed this event" }
  validates :comment, length: { minimum: 10, maximum: 1000 }

  validate :movie_matches_event

  private

  def movie_matches_event
    return unless movie && event

    errors.add(:movie, "must match the event's movie") if movie != event.movie
  end
end

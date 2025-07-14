class Review < ApplicationRecord
  belongs_to :user
  belongs_to :movie
  belongs_to :event

  validates :rating, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: {
    scope: [ :movie_id, :event_id ],
    message: "You have already reviewed this event"
  }
  validates :comment, length: { minimum: 10, maximum: 1000 }

  validate :user_must_have_attended_event

  private

  def user_must_have_attended_event
    unless event.users.include?(user)
      errors.add(:user, "must have attended the event to leave a review")
    end
  end
end

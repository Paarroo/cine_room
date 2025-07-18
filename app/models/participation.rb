class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id, message: "User already registered for this event" }
  validates :seats, numericality: { only_integer: true, greater_than: 0 }
  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending

   # Scope for upcoming events (based on event date)
  scope :upcoming, -> { joins(:event).where('events.event_date >= ?', Date.today).order('events.event_date ASC') }

  # Scope for past events
  scope :past, -> { joins(:event).where('events.event_date < ?', Date.today).order('events.event_date DESC') }
end

class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id, message: "User already registered for this event" }
  validates :seats, numericality: { only_integer: true, greater_than: 0 }
  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending
end

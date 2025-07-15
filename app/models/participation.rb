class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :event
end
class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id, message: "User already registered for this event" }

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending
end

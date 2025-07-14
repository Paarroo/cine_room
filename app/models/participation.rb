class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: {
    scope: :event_id,
    message: "You have already registered for this event"
  }
  validates :status, inclusion: { in: %w[pending confirmed cancelled] }
  scope :pending, -> { where(status: 'pending') }
    scope :confirmed, -> { where(status: 'confirmed') }
    scope :cancelled, -> { where(status: 'cancelled') }

  before_create :check_event_capacity

  private

  def check_event_capacity
    if event.available_spots <= 0
      errors.add(:event, "is sold out")
      throw(:abort)
    end
  end
end

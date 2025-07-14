class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id, message: "User already registered for this event" }

  STATUSES = %w[pending confirmed cancelled].freeze

  validates :status, inclusion: { in: STATUSES }

  after_initialize :set_default_status, if: :new_record?

  def pending?
    status == 'pending'
  end

  def confirmed?
    status == 'confirmed'
  end

  def cancelled?
    status == 'cancelled'
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end
end

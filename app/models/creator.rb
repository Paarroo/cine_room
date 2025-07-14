class Creator < ApplicationRecord
  belongs_to :user
  has_many :movies, dependent: :destroy

  validates :user_id, uniqueness: true
  validates :bio, length: { maximum: 1000 }

  STATUSES = %w[pending verified rejected].freeze

  validates :status, inclusion: { in: STATUSES }

  after_initialize :set_default_status, if: :new_record?

  def pending?
    status == 'pending'
  end

  def verified?
    status == 'verified'
  end

  def rejected?
    status == 'rejected'
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end
end

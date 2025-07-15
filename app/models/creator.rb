class Creator < ApplicationRecord
  belongs_to :user
  has_many :movies, dependent: :destroy

  validates :user_id, uniqueness: true
  validates :bio, length: { maximum: 1000 }

  enum :status, { pending: 0, verified: 1, rejected: 2 }, default: :pending
end

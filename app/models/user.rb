class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :events, through: :participations
  has_one :creator, dependent: :destroy

  validates :first_name, :last_name, presence: true

  ROLES = %w[user admin].freeze

  validates :role, inclusion: { in: ROLES }

  def admin?
    role == 'admin'
  end

  def user?
    role == 'user' || role.blank?
  end

  private

  def set_default_role
    self.role ||= 'user'
  end
end

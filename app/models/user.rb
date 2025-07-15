class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :events, through: :participations
  has_one :creator, dependent: :destroy

  validates :first_name, :last_name, presence: true

  enum :role, { user: 0, creator: 1, admin: 2 }, default: :user
end

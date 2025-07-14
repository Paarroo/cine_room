class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :events, through: :participations

  validates :first_name, :last_name, presence: true
end

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :movie
  belongs_to :event

  validates :rating, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: [ :movie_id, :event_id ], message: "Tu as déjà commenté ce film" }
  validates :comment, length: { minimum: 10, maximum: 1000 }, presence: true

end

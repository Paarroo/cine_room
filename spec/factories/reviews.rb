FactoryBot.define do
  factory :review do
    association :user
    association :movie
    association :event
    rating { rand(1..5) }
    comment { Faker::Movie.quote }
  end
end

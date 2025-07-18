FactoryBot.define do
  factory :movie do
    association :user
    title { Faker::Movie.title }
    synopsis { Faker::Lorem.paragraph }
    director { Faker::Name.name }
    duration { rand(80..180) }
    genre { %w[action drama horror comedy sci-fi romance].sample }
    year { rand(1990..2024) }
    trailer_url { Faker::Internet.url }
    poster_url { Faker::Internet.url }
    validation_status { 0 }
  end
end

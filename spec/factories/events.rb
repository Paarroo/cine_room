FactoryBot.define do
  factory :event do
    association :movie
    title { "#{movie.title} Screening" }
    description { Faker::Lorem.sentence }
    venue_name { Faker::Restaurant.name }
    venue_address { Faker::Address.full_address }
    event_date { Faker::Date.forward(days: rand(10..30)) }
    start_time { Time.now.change(hour: rand(17..21), min: [0, 15, 30, 45].sample) }
    max_capacity { rand(30..100) }
    price_cents { rand(500..2000) }
    status { 0 }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end
end

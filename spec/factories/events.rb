FactoryBot.define do
  factory :event do
    association :movie
    title { "#{movie.title} - Rencontre avec #{movie.director}" }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    venue_name { [ 'Galerie Marais', 'Rooftop République', 'Hôtel Particulier', 'Loft Belleville' ].sample }
    venue_address { Faker::Address.full_address }
    event_date { Faker::Date.between(from: 1.week.from_now, to: 3.months.from_now) }
    start_time { [ '19:00', '19:30', '20:00', '20:30', '21:00' ].sample }
    max_capacity { Faker::Number.between(from: 15, to: 30) }
    price_cents { Faker::Number.between(from: 20, to: 40) * 100 }
    status { :upcoming }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end
end

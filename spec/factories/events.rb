FactoryBot.define do
  factory :event do
    association :movie, factory: [ :movie, :validated ]
    title { "Projection de #{movie.title}" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    venue_name { Faker::Company.name + " Cinema" }
    venue_address { Faker::Address.full_address }
    event_date { rand(1.week.from_now..3.months.from_now).to_date }
    start_time { [ '19:00', '20:30', '21:00', '18:30', '22:00' ].sample }
    max_capacity { rand(50..200) }
    price_cents { rand(800..2500) }
    status { [ :upcoming, :completed, :sold_out ].sample }
    latitude { Faker::Address.latitude.to_f }
    longitude { Faker::Address.longitude.to_f }

    trait :upcoming do
      status { :upcoming }
      event_date { rand(1.week.from_now..2.months.from_now).to_date }
    end

    trait :completed do
      status { :completed }
      event_date { rand(6.months.ago..1.week.ago).to_date }
    end

    trait :sold_out do
      status { :sold_out }
      event_date { rand(1.week.from_now..1.month.from_now).to_date }
    end
  end
end

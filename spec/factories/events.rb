FactoryBot.define do
  factory :event do
    association :movie
    title { "Projection de #{movie&.title || 'Film'}" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    venue_name { [ "Galerie Marais", "Rooftop République", "Mansion 16e", "Loft Belleville", "Studio Montmartre" ].sample }
    venue_address { "#{Faker::Address.street_address}, #{[ '75001', '75003', '75004', '75011', '75016', '75018', '75020' ].sample} Paris" }
    event_date { Faker::Date.between(from: 1.month.ago, to: 2.months.from_now) }
    start_time { [ "19:00", "19:30", "20:00", "20:30" ].sample }
    max_capacity { [ 15, 20, 25, 30, 35, 40 ].sample }
    price_cents { [ 1500, 1800, 2000, 2200, 2500, 3000 ].sample } # 15€ à 30€
    status { rand > 0.1 ? "upcoming" : [ "sold_out", "completed", "cancelled" ].sample }
    latitude { Faker::Address.latitude.to_f.round(6) }
    longitude { Faker::Address.longitude.to_f.round(6) }


    after(:build) do |event|
      if event.event_date < Date.current
        event.status = "completed"
      end
    end
  end
end

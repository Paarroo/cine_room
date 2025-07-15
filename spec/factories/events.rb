FactoryBot.define do
  factory :event do
    movie { nil }
    title { "MyString" }
    description { "MyText" }
    venue_name { "MyString" }
    venue_address { "MyString" }
    event_date { "2025-07-15" }
    start_time { "2025-07-15 11:10:26" }
    max_capacity { 1 }
    price_cents { 1 }
    status { 1 }
    latitude { "9.99" }
    longitude { "9.99" }
  end
end

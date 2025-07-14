FactoryBot.define do
  factory :event do
    movie { nil }
    title { "MyString" }
    description { "MyText" }
    venue_name { "MyString" }
    venue_address { "MyString" }
    event_date { "2025-07-14" }
    start_time { "2025-07-14 10:46:09" }
    max_capacity { 1 }
    price_cents { 1 }
    status { "MyString" }
  end
end

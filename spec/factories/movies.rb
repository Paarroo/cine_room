FactoryBot.define do
  factory :movie do
    creator { nil }
    title { "MyString" }
    synopsis { "MyText" }
    director { "MyString" }
    duration { 1 }
    genre { "MyString" }
    language { "MyString" }
    year { 1 }
    trailer_url { "MyString" }
    poster_url { "MyString" }
    validation_status { 1 }
    validated_by { nil }
    validated_at { "2025-07-15 11:10:15" }
  end
end

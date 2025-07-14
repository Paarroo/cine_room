FactoryBot.define do
  factory :movie do
    title { "MyString" }
    synopsis { "MyText" }
    director { "MyString" }
    duration { 1 }
    genre { "MyString" }
    language { "MyString" }
    year { 1 }
    trailer_url { "MyString" }
    poster_url { "MyString" }
  end
end

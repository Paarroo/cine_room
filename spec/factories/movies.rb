FactoryBot.define do
  factory :movie do
    title { Faker::Movie.title }
    synopsis { Faker::Lorem.paragraph(sentence_count: 5) }
    director { Faker::Name.name }
    duration { rand(80..180) }
    genre { [ 'Drame', 'Comédie', 'Thriller', 'Documentaire', 'Science-Fiction' ].sample }
    language { [ 'fr', 'en', 'es' ].sample }
    year { rand(2015..2024) }
    trailer_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alpha(number: 11)}" }
    poster_url { Faker::LoremFlickr.image(size: "300x450", search_terms: [ 'movie' ]) }
    validation_status { :pending }

    association :user, factory: [ :user, :creator ]  # <- CHANGEMENT ICI
  end
end

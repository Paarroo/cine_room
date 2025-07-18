FactoryBot.define do
  factory :movie do
    association :user, factory: [ :user, :creator ]
    title { Faker::Movie.title }
    synopsis { Faker::Lorem.paragraph(sentence_count: 5) }
    director { Faker::Name.name }
    duration { rand(80..180) }
    genre { [ 'Drame', 'Comédie', 'Thriller', 'Documentaire', 'Science-Fiction', 'Romance', 'Horreur', 'Animation' ].sample }
    language { [ 'fr', 'en', 'es' ].sample }
    year { rand(2015..2024) }
    trailer_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alpha(number: 11)}" }
    poster_url { Faker::LoremFlickr.image(size: "300x450", search_terms: [ 'movie', 'cinema' ]) }
    validation_status { [ :pending, :validated, :rejected ].sample }

    trait :validated do
      validation_status { :validated }
      validated_at { rand(1.month.ago..Time.current) }
    end

    trait :pending do
      validation_status { :pending }
    end

    trait :rejected do
      validation_status { :rejected }
      validated_at { rand(1.month.ago..Time.current) }
    end
  end
end

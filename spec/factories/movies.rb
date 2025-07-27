

FactoryBot.define do
  factory :movie do
    title { Faker::Movie.title }
    synopsis { Faker::Lorem.paragraph(sentence_count: 5) }
    director { Faker::Name.name }
    duration { rand(80..180) }
    genre { %w[Drame Comédie Thriller Documentaire Science-Fiction].sample }
    language { %w[fr en es].sample }
    year { rand(2015..2024) }
    trailer_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alpha(number: 11)}" }
    validation_status { :pending }

    trait :approved do
      validation_status { :approved }
      validated_by { User.find_by(role: :admin) || association(:user, :admin) }
    end

    trait :rejected do
      validation_status { :rejected }
      validated_by { User.find_by(role: :admin) || association(:user, :admin) }
    end

    trait :validated do
      validation_status { :approved }
      validated_by { User.find_by(role: :admin) || association(:user, :admin) }
    end

    user { association(:user, :creator) }

    after(:build) do |movie|
      movie.authorship_confirmed = "1"

      # Skip poster attachment to avoid network dependencies and missing fixtures
      # Poster can be added manually through the UI when needed
    end
  end
end



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
      association :validated_by, factory: [:user, :admin]
    end

    trait :rejected do
      validation_status { :rejected }
      association :validated_by, factory: [:user, :admin]
    end

    trait :validated do
      validation_status { :approved }
      association :validated_by, factory: [:user, :admin]
    end

    association :user, factory: [:user, :creator]

    after(:build) do |movie|
      movie.authorship_confirmed = "1"

      urls = [
        "https://source.unsplash.com/300x450/?cinema",
        "https://source.unsplash.com/300x450/?movie-poster",
        "https://source.unsplash.com/300x450/?film",
        
      ]

      # Génère un poster aléatoire depuis Unsplash
      begin
        file = URI.open(urls.sample)
      rescue OpenURI::HTTPError => e
        puts "⚠️ Poster download failed: #{e.message}"
        file = File.open(Rails.root.join("spec/fixtures/files/test-poster.jpg")) # fallback
      end

      movie.poster.attach(
        io: file,
        filename: "poster.jpg",
        content_type: "image/jpeg"
      )
    end
  end
end

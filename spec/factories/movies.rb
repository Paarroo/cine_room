

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
      validated_by { association(:user, :admin) }
    end

    trait :rejected do
      validation_status { :rejected }
      validated_by { association(:user, :admin) }
    end

    trait :validated do
      validation_status { :approved }
      validated_by { association(:user, :admin) }
    end

    user { association(:user, :creator) }

    after(:build) do |movie|
      movie.authorship_confirmed = "1"

      # Skip poster attachment in production to avoid network dependencies
      next if Rails.env.production?

      urls = [
        "https://source.unsplash.com/300x450/?cinema",
        "https://source.unsplash.com/300x450/?movie-poster",
        "https://source.unsplash.com/300x450/?film",
        
      ]

      # Generates a random poster from Unsplash (dev/test only)
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

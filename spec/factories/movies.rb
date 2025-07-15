FactoryBot.define do
  factory :movie do
    association :creator
    title { Faker::Movie.title }
    synopsis { Faker::Lorem.paragraph(sentence_count: 4) }
    director { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
    duration { Faker::Number.between(from: 80, to: 180) }
    genre { [ 'Drame', 'Comédie', 'Thriller', 'Documentaire', 'Romance' ].sample }
    language { 'Français' }
    year { Faker::Number.between(from: 2020, to: 2024) }
    trailer_url { "https://youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}" }
    poster_url { "https://via.placeholder.com/400x600/#{Faker::Color.hex_color.delete('#')}/ffffff" }
    validation_status { :approved }
    validated_at { Faker::Time.between(from: 1.year.ago, to: 6.months.ago) }
  end
end

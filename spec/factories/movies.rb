FactoryBot.define do
  factory :movie do
    title { Faker::Movie.title }
    synopsis { Faker::Lorem.paragraph(sentence_count: 4) }
    director { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
    duration { rand(85..180) }
    genre { [ "Drame", "Comédie", "Thriller", "Documentaire", "Romance", "Science-fiction" ].sample }
    language { [ "Français", "Anglais", "Italien", "Espagnol" ].sample }
    year { rand(2018..2024) }
    trailer_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alpha(number: 11)}" }
    poster_url { "https://picsum.photos/400/600?random=#{rand(1000)}" }
  end
end

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    bio { Faker::Lorem.paragraph(sentence_count: 3) }
    role { :user }

    trait :admin do
      role { :admin }
      email { "admin@cineroom.com" }
      first_name { "Name" }
      last_name { "User" }
    end

    trait :creator do
      role { :user }
      bio { "Passionné de cinéma indépendant, je crée des films depuis #{rand(2..15)} ans." }
    end
  end
end

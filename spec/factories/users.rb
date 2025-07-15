FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    role { :user }
    bio { Faker::Lorem.paragraph(sentence_count: 2) }

    trait :creator do
      role { :creator }
    end
  end
end

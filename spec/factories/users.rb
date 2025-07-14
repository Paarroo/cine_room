FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { "password123" }


    trait :admin do
      role { 1 }
      email { "admin@cineroom.com" }
    end
  end
end

FactoryBot.define do
  factory :review do
    association :user
    association :movie
    association :event
    rating { Faker::Number.between(from: 3, to: 5) }
    comment { Faker::Lorem.paragraph(sentence_count: rand(2..4)) }
  end
end

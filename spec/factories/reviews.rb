FactoryBot.define do
  factory :review do
    association :user
    association :movie, factory: [ :movie, :validated ]
    association :event, factory: [ :event, :completed ]
    rating { rand(1..5) }
    comment { Faker::Lorem.paragraph(sentence_count: rand(2..4)) }

    after(:build) do |review|
      review.event.movie = review.movie
    end

    trait :excellent do
      rating { [ 4, 5 ].sample }
      comment { "#{Faker::Lorem.sentence} Vraiment excellent ! #{Faker::Lorem.sentence}" }
    end

    trait :poor do
      rating { [ 1, 2 ].sample }
      comment { "#{Faker::Lorem.sentence} Malheureusement décevant. #{Faker::Lorem.sentence}" }
    end

    trait :no_comment do
      comment { nil }
    end
  end
end

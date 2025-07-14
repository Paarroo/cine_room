FactoryBot.define do
  factory :review do
    association :user
    association :movie
    association :event

    comment { Faker::Lorem.paragraph(sentence_count: rand(2..4)) }


    after(:build) do |review|
      review.movie = review.event.movie if review.event
    end
  end
end

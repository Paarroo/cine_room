FactoryBot.define do
  factory :creator do
    association :user, factory: [ :user, :creator ]
    bio { Faker::Lorem.paragraph(sentence_count: 3) }
    status { :verified }
    verified_at { Faker::Time.between(from: 2.years.ago, to: 1.year.ago) }
  end
end

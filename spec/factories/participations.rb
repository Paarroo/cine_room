FactoryBot.define do
  factory :participation do
    association :user
    association :event
    status { 0 }
    seats { rand(1..3) }
    stripe_payment_id { Faker::Alphanumeric.alphanumeric(number: 10) }
  end
end

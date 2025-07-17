FactoryBot.define do
  factory :participation do
    association :user
    association :event
    status { :confirmed }
    stripe_payment_id { "pi_#{Faker::Alphanumeric.alphanumeric(number: 24)}" }
  end
end

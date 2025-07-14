FactoryBot.define do
  factory :participation do
    association :user
    association :event
    stripe_payment_id { "pi_#{Faker::Alphanumeric.alphanumeric(number: 24)}" }
    status { [ "pending", "confirmed", "cancelled" ].sample }


    after(:build) do |participation|
      participation.status = "confirmed" if rand > 0.2
    end
  end
end

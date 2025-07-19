FactoryBot.define do
  factory :participation do
    association :user
    association :event, factory: [ :event, :upcoming ]
    status { [ :pending, :confirmed, :cancelled ].sample }
    seats { rand(1..4) }
    stripe_payment_id { "pi_#{Faker::Alphanumeric.alphanumeric(number: 24)}" if status == 'confirmed' }

    trait :confirmed do
      status { :confirmed }
      stripe_payment_id { "pi_#{Faker::Alphanumeric.alphanumeric(number: 24)}" }
    end

    trait :pending do
      status { :pending }
      stripe_payment_id { nil }
    end

    trait :cancelled do
      status { :cancelled }
      stripe_payment_id { nil }
    end
  end
end

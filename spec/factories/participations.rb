FactoryBot.define do
  factory :participation do
    user { nil }
    event { nil }
    stripe_payment_id { "MyString" }
    status { 1 }
  end
end

FactoryBot.define do
  factory :review do
    user { nil }
    movie { nil }
    event { nil }
    rating { 1 }
    comment { "MyText" }
  end
end

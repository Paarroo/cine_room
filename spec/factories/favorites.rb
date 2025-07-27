FactoryBot.define do
  factory :favorite do
    association :user
    association :movie
  end
end
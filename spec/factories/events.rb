FactoryBot.define do
  factory :event do
    association :movie, factory: [:movie, :validated]
    title { "Projection de #{movie.title}" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    venue_name { ["Cinéma Rex", "Gaumont", "UGC", "MK2", "Pathé", "Le Grand Action", "Studio des Ursulines", "Cinéma du Panthéon"].sample }
    venue_address { 
      [
        "1 Boulevard Poissonnière, 75002 Paris",
        "30 Avenue d'Italie, 75013 Paris", 
        "14 Rue Lincoln, 75008 Paris",
        "128 Avenue de France, 75013 Paris",
        "19 Rue de Vaugirard, 75006 Paris",
        "5 Rue Banquier, 75013 Paris",
        "10 Rue des Ursulines, 75005 Paris",
        "13 Rue Victor Cousin, 75005 Paris",
        "22 Rue Saint-Antoine, 75004 Paris",
        "15 Rue de la Gaîté, 75014 Paris",
        "73 Boulevard de Strasbourg, 75010 Paris",
        "66 Avenue des Champs-Élysées, 75008 Paris"
      ].sample
    }
    event_date { rand(1.week.from_now..3.months.from_now).to_date }
    start_time { [ '19:00', '20:30', '21:00', '18:30', '22:00' ].sample }
    max_capacity { rand(50..100) }
    price_cents { rand(800..2500) }
    status { [ :upcoming, :finished, :sold_out ].sample }
    # Coordinates will be set by geocoding, removed fake ones
    latitude { nil }
    longitude { nil }

    trait :upcoming do
      status { :upcoming }
      event_date { rand(1.week.from_now..2.months.from_now).to_date }
    end

    trait :completed do
      status { :finished }
      event_date { rand(1.week.from_now..2.months.from_now).to_date }
      
      after(:create) do |event|
        # Force the completed status after creation to bypass validation
        event.update_column(:status, :finished)
        event.update_column(:event_date, rand(6.months.ago..1.week.ago).to_date)
      end
    end

    trait :finished do
      status { :finished }
      event_date { rand(1.week.from_now..2.months.from_now).to_date }
      
      after(:create) do |event|
        # Force the finished status after creation to bypass validation
        event.update_column(:status, :finished)
        event.update_column(:event_date, rand(6.months.ago..1.week.ago).to_date)
      end
    end

    trait :ongoing do
      status { :ongoing }
      event_date { rand(1.week.from_now..2.months.from_now).to_date }
      
      after(:create) do |event|
        # Force the ongoing status after creation to bypass validation
        event.update_column(:status, :ongoing)
        event.update_column(:event_date, 1.day.ago.to_date)
      end
    end

    trait :sold_out do
      status { :sold_out }
      event_date { rand(1.week.from_now..1.month.from_now).to_date }
    end
  end
end

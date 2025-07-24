require 'faker'

if Rails.env.development? || Rails.env.test?
  require 'factory_bot_rails'
end

puts " Seeding the database..."

if Rails.env.production?
  puts "Production seeding - creating complete dataset without FactoryBot..."
  
  puts "Cleaning database..."
  Review.destroy_all
  Participation.destroy_all
  Event.destroy_all
  Movie.destroy_all
  User.destroy_all

  puts "Creating admin user..."
  admin = User.create!(
    email: 'admin@cineroom.com',
    first_name: 'Admin',
    last_name: 'CinéRoom',
    password: 'password123',
    password_confirmation: 'password123',
    role: 'admin',
    confirmed_at: Time.current
  )

  puts "Creating regular users..."
  users = []
  10.times do |i|
    users << User.create!(
      email: "user#{i+1}@cineroom.com",
      first_name: ["Alice", "Bob", "Charlie", "Diana", "Eva", "Frank", "Grace", "Henry", "Iris", "Jack"][i],
      last_name: ["Martin", "Dubois", "Moreau", "Laurent", "Simon", "Michel", "Leroy", "Garnier", "Faure", "Andre"][i],
      password: 'password123',
      password_confirmation: 'password123',
      role: 'user',
      confirmed_at: Time.current
    )
  end

  puts "Creating creators..."
  creators = []
  5.times do |i|
    creators << User.create!(
      email: "creator#{i+1}@cineroom.com", 
      first_name: ["Marc", "Sophie", "Paul", "Julie", "David"][i],
      last_name: ["Réalisateur", "Cinéaste", "Producer", "Director", "Filmmaker"][i],
      password: 'password123',
      password_confirmation: 'password123',
      role: 'creator',
      confirmed_at: Time.current
    )
  end

  puts "Creating movies..."
  movies = []
  movie_titles = [
    "Le Dernier Voyage", "Nuits de Tokyo", "L'Écho du Temps", 
    "Reflets d'Automne", "La Danse des Ombres", "Horizon Perdu",
    "Les Murmures du Vent", "Clair de Lune", "L'Art de Vivre"
  ]
  
  creators.each_with_index do |creator, i|
    2.times do |j|
      movies << Movie.create!(
        title: movie_titles[i*2 + j],
        description: "Un film captivant qui explore les thèmes universels de l'humanité à travers une histoire unique et touchante.",
        genre: ["Drame", "Thriller", "Comédie", "Romance", "Action"].sample,
        duration: [90, 105, 120, 135, 150].sample,
        release_date: Date.current - rand(1..5).years,
        user: creator,
        status: 'approved',
        validated_by: admin,
        validated_at: Time.current
      )
    end
  end

  puts "Creating events..."
  events = []
  movies.each do |movie|
    rand(1..3).times do
      events << Event.create!(
        title: "Projection de #{movie.title}",
        description: "Venez découvrir ce magnifique film dans une ambiance conviviale.",
        start_date: Time.current + rand(1..30).days,
        end_date: Time.current + rand(31..60).days,
        location: ["Cinéma Le Grand Rex", "MK2 Bibliothèque", "Pathé Châtelet", "UGC Ciné Cité"].sample,
        address: ["1 bd Poissonnière, Paris", "128-162 Av. de France, Paris", "Place du Châtelet, Paris", "19 Rue Berger, Paris"].sample,
        max_capacity: [20, 30, 40, 50].sample,
        price_cents: [800, 1000, 1200, 1500].sample,
        status: 'upcoming',
        movie: movie
      )
    end
  end

  puts "Creating some completed events..."
  past_events = []
  movies.sample(3).each do |movie|
    past_events << Event.create!(
      title: "Projection de #{movie.title} (passée)",
      description: "Projection terminée avec succès.",
      start_date: Time.current - rand(30..90).days,
      end_date: Time.current - rand(10..29).days,
      location: "Cinéma Vintage",
      address: "15 Rue de la Paix, Paris",
      max_capacity: 25,
      price_cents: 1000,
      status: 'completed',
      movie: movie
    )
  end

  puts "Creating participations..."
  events.each do |event|
    participants_count = rand(1..5)
    users.sample(participants_count).each do |user|
      next if event.users.include?(user)
      
      Participation.create!(
        user: user,
        event: event,
        status: event.completed? ? 'confirmed' : ['pending', 'confirmed'].sample,
        seats: rand(1..3),
        total_price_cents: event.price_cents * rand(1..3)
      )
    end
  end

  puts "Creating reviews for past events..."
  past_events.each do |event|
    event.participations.each do |participation|
      next if rand > 0.7
      
      Review.create!(
        user: participation.user,
        event: event,
        movie: event.movie,
        rating: rand(3..5),
        comment: [
          "Excellente soirée cinéma ! Une expérience mémorable.",
          "Film captivant, je recommande vivement.",
          "Très bonne organisation, ambiance chaleureuse.",
          "Un moment de détente parfait après une longue semaine.",
          "Belle découverte cinématographique !"
        ].sample
      )
    end
  end

  puts " Production seeding complete!"
  puts "Created:"
  puts "  Users: #{User.count} (#{User.where(role: 'admin').count} admin, #{User.where(role: 'creator').count} creators, #{User.where(role: 'user').count} users)"
  puts "  Movies: #{Movie.count}"
  puts "  Events: #{Event.count} (#{Event.where(status: 'upcoming').count} upcoming, #{Event.where(status: 'completed').count} completed)"
  puts "  Participations: #{Participation.count}"
  puts "  Reviews: #{Review.count}"
  exit
end

puts "Development/Test seeding - creating full dataset..."

puts "Cleaning database..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
User.destroy_all

puts "Creating admin user..."
admin = FactoryBot.create(:user, :admin)

puts "Creating #{10} regular users..."
regular_users = FactoryBot.create_list(:user, 10)

puts "Creating #{5} creators..."
creators = FactoryBot.create_list(:user, 5, :creator)

puts "Creating approved movies for creators..."
approved_movies = []
creators.each do |creator|
  movies = FactoryBot.create_list(:movie, rand(2..4), :approved, user: creator, validated_by: admin)
  approved_movies.concat(movies)
end

puts "Creating pending movies for some creators..."
creators.sample(3).each do |creator|
  FactoryBot.create_list(:movie, rand(1..2), user: creator)
end

puts "Creating events for approved movies..."
approved_movies.each do |movie|
  FactoryBot.create_list(:event, rand(1..3), :upcoming, movie: movie)
  FactoryBot.create_list(:event, rand(0..2), :completed, movie: movie) if [ true, false ].sample
end

puts "Creating some sold out events..."
Event.upcoming.sample(rand(3..5)).each do |event|
  event.update!(status: :sold_out)
end

puts "Creating participations for events..."
Event.all.each do |event|
  next if event.sold_out?

  participants_count = case event.status
  when 'upcoming'
    rand(1..5)
  when 'completed'
    rand(3..8)
  when 'sold_out'
    event.max_capacity
  else
    0
  end

  participants = regular_users.sample(participants_count)
  participants.each do |user|
    next if event.users.include?(user)

    participation = FactoryBot.create(:participation,
      user: user,
      event: event,
      status: event.completed? ? :confirmed : [ :pending, :confirmed ].sample,
      seats: rand(1..3)
    )
  end
end

puts "Creating reviews for completed events..."
Event.completed.each do |event|
  event.participations.confirmed.each do |participation|
    next if rand > 0.7 # 70% chance de laisser un avis

    FactoryBot.create(:review,
      user: participation.user,
      event: event,
      movie: event.movie,
      rating: rand(1..5),
      comment: [
        "Excellente soirée cinéma ! #{Faker::Lorem.sentence}",
        "Une expérience inoubliable. #{Faker::Lorem.sentence}",
        "Film intéressant, mais #{Faker::Lorem.sentence}",
        "Décevant malheureusement. #{Faker::Lorem.sentence}",
        "Parfait pour une sortie entre amis ! #{Faker::Lorem.sentence}"
      ].sample
    )
  end
end

puts " Database seeded successfully!"
puts "Created:"
puts "  Users: #{User.count} (#{User.admin_users.count} admin, #{User.creators.count} creators, #{User.regular_users.count} users)"
puts "  Movies: #{Movie.count} (#{Movie.approved.count} approved, #{Movie.pending.count} pending)"
puts "  Events: #{Event.count} (#{Event.upcoming.count} upcoming, #{Event.completed.count} completed, #{Event.sold_out.count} sold out)"
puts "  Participations: #{Participation.count} (#{Participation.confirmed.count} confirmed)"
puts " Reviews: #{Review.count}"
puts " Seeding complete!"

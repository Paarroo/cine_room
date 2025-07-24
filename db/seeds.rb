require 'faker'

if Rails.env.development? || Rails.env.test?
  require 'factory_bot_rails'
end

puts " Seeding the database..."

if Rails.env.production?
  puts "Production seeding - creating complete dataset without FactoryBot..."
  
  # Disable welcome email during seeding only
  puts "Disabling welcome emails for seeding process..."
  User.skip_callback(:create, :after, :send_welcome_email)
  
  # Create a default poster for seeding
  puts "Creating default poster for movies..."
  require 'open-uri'
  default_poster_path = Rails.root.join('tmp', 'default_poster.jpg')
  
  # Create a simple placeholder image if it doesn't exist
  unless File.exist?(default_poster_path)
    FileUtils.mkdir_p(File.dirname(default_poster_path))
    # Create a simple 1x1 pixel image
    File.open(default_poster_path, 'wb') do |file|
      # Minimal JPEG header for a 1x1 pixel image
      file.write([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12, 0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, 0x8A, 0x00, 0x07, 0xFF, 0xD9].pack('C*'))
    end
  end
  
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
      movie = Movie.new(
        title: movie_titles[i*2 + j],
        synopsis: "Un film captivant qui explore les thèmes universels de l'humanité à travers une histoire unique et touchante.",
        director: creator.full_name,
        genre: ["Drame", "Thriller", "Comédie", "Romance", "Action"].sample,
        duration: [90, 105, 120, 135, 150].sample,
        year: Date.current.year - rand(1..5),
        language: "Français",
        user: creator,
        validation_status: 'approved',
        validated_by: admin,
        validated_at: Time.current,
        authorship_confirmed: "1"
      )
      
      # Attach the default poster
      movie.poster.attach(
        io: File.open(default_poster_path),
        filename: 'default_poster.jpg',
        content_type: 'image/jpeg'
      )
      
      movie.save!
      movies << movie
    end
  end

  puts "Creating events..."
  events = []
  movies.each do |movie|
    rand(1..3).times do
      event_date = Date.current + rand(7..30).days # Ensure it's at least 1 week from now
      events << Event.create!(
        title: "Projection de #{movie.title}",
        description: "Venez découvrir ce magnifique film dans une ambiance conviviale.",
        venue_name: ["Cinéma Le Grand Rex", "MK2 Bibliothèque", "Pathé Châtelet", "UGC Ciné Cité"].sample,
        venue_address: ["1 bd Poissonnière, Paris", "128-162 Av. de France, Paris", "Place du Châtelet, Paris", "19 Rue Berger, Paris"].sample,
        event_date: event_date,
        start_time: Time.current.change(hour: [18, 19, 20, 21].sample, min: [0, 30].sample),
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
    past_event_date = Date.current - rand(30..90).days
    event = Event.new(
      title: "Projection de #{movie.title} (passée)",
      description: "Projection terminée avec succès.",
      venue_name: "Cinéma Vintage",
      venue_address: "15 Rue de la Paix, Paris",
      event_date: past_event_date,
      start_time: Time.current.change(hour: 20, min: 0),
      max_capacity: 25,
      price_cents: 1000,
      status: 'finished',
      movie: movie
    )
    # Save without validations to bypass date validation
    event.save!(validate: false)
    past_events << event
  end

  puts "Creating participations..."
  events.each do |event|
    participants_count = rand(1..5)
    users.sample(participants_count).each do |user|
      next if event.users.include?(user)
      
      Participation.create!(
        user: user,
        event: event,
        status: event.finished? ? 'confirmed' : ['pending', 'confirmed'].sample,
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

  # Re-enable welcome email callback for normal user registration
  puts "Re-enabling welcome emails for normal operation..."
  User.set_callback(:create, :after, :send_welcome_email)
  
  # Clean up temporary poster file
  File.delete(default_poster_path) if File.exist?(default_poster_path)
  
  puts " Production seeding complete!"
  puts "Created:"
  puts "  Users: #{User.count} (#{User.where(role: 'admin').count} admin, #{User.where(role: 'creator').count} creators, #{User.where(role: 'user').count} users)"
  puts "  Movies: #{Movie.count} (#{Movie.where(validation_status: 'approved').count} approved)"
  puts "  Events: #{Event.count} (#{Event.where(status: 'upcoming').count} upcoming, #{Event.where(status: 'finished').count} finished)"
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

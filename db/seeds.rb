Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
Creator.destroy_all
User.destroy_all

# Create test user (role sera automatiquement 0 = 'user')
test_user = User.create!(
  email: 'test@cineroom.com',
  password: 'password123',
  first_name: 'Test',
  last_name: 'User'
)

# Create creators with creator role
creators_data = [
  {
    email: 'claire.martin@example.com',
    first_name: 'Claire',
    last_name: 'Martin',
    bio: 'Réalisatrice primée au Festival de Cannes 2024.',
    role: 'creator'
  },
  {
    email: 'marc.dubois@example.com',
    first_name: 'Marc',
    last_name: 'Dubois',
    bio: 'Documentariste de la nouvelle génération.',
    role: 'creator'
  },
  {
    email: 'sophie.leroy@example.com',
    first_name: 'Sophie',
    last_name: 'Leroy',
    bio: 'Réalisatrice fiction multi-primée.',
    role: 'creator'
  },
  {
    email: 'antoine.rousseau@example.com',
    first_name: 'Antoine',
    last_name: 'Rousseau',
    bio: 'Jeune prodige du cinéma indépendant.',
    role: 'creator'
  }
]

creators = []
creators_data.each do |creator_data|
  user = User.create!(
    email: creator_data[:email],
    password: 'password123',
    first_name: creator_data[:first_name],
    last_name: creator_data[:last_name],
    role: creator_data[:role]
  )

  creator = Creator.create!(
    user: user,
    bio: creator_data[:bio],
    status: 'verified',
    verified_at: 1.year.ago
  )
  creators << creator
end

# Create regular users
regular_users = []
10.times do
  user = User.create!(
    email: Faker::Internet.unique.email,
    password: 'password123',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name
  )
  regular_users << user
end

# Create admin user
admin = User.create!(
  email: 'admin@cineroom.com',
  password: 'password123',
  first_name: 'Admin',
  last_name: 'CinéRoom',
  role: 'admin'
)

# Create movies
movies_data = [
  {
    creator: creators[0],
    title: 'Le Souffle',
    synopsis: 'Dans une petite ville de province, Emma, jeune kinésithérapeute, découvre que sa patiente âgée cache un lourd secret familial.',
    director: 'Claire Martin',
    duration: 95,
    genre: 'Drame',
    language: 'Français',
    year: 2024,
    trailer_url: 'https://youtube.com/watch?v=example1',
    poster_url: 'https://via.placeholder.com/400x600/dc2626/ffffff?text=Le+Souffle',
    validation_status: 'approved'
  },
  {
    creator: creators[1],
    title: 'Fragments',
    synopsis: 'Un documentaire bouleversant qui suit trois familles pendant une année difficile.',
    director: 'Marc Dubois',
    duration: 108,
    genre: 'Documentaire',
    language: 'Français',
    year: 2024,
    trailer_url: 'https://youtube.com/watch?v=example2',
    poster_url: 'https://via.placeholder.com/400x600/7c3aed/ffffff?text=Fragments',
    validation_status: 'approved'
  },
  {
    creator: creators[2],
    title: 'L\'Aube',
    synopsis: 'Comédie douce-amère sur trois trentenaires qui se retrouvent pour organiser l\'enterrement de leur ami d\'enfance.',
    director: 'Sophie Leroy',
    duration: 87,
    genre: 'Comédie dramatique',
    language: 'Français',
    year: 2024,
    trailer_url: 'https://youtube.com/watch?v=example3',
    poster_url: 'https://via.placeholder.com/400x600/059669/ffffff?text=L\'Aube',
    validation_status: 'approved'
  },
  {
    creator: creators[3],
    title: 'Marées',
    synopsis: 'Thriller psychologique sophistiqué. Un architecte découvre que les plans qu\'il dessine influencent mystérieusement la réalité.',
    director: 'Antoine Rousseau',
    duration: 103,
    genre: 'Thriller',
    language: 'Français',
    year: 2024,
    trailer_url: 'https://youtube.com/watch?v=example4',
    poster_url: 'https://via.placeholder.com/400x600/dc2626/ffffff?text=Marées',
    validation_status: 'approved'
  }
]

movies = []
movies_data.each do |movie_data|
  movie = Movie.create!(movie_data)
  movies << movie
end

# Create events
venues_data = [
  {
    name: 'Galerie Marais',
    address: '15 rue des Rosiers, 75004 Paris',
    latitude: 48.8566,
    longitude: 2.3522
  },
  {
    name: 'Rooftop République',
    address: 'Place de la République, 75011 Paris',
    latitude: 48.8676,
    longitude: 2.3631
  },
  {
    name: 'Hôtel Particulier Mansion',
    address: 'Avenue Foch, 75016 Paris',
    latitude: 48.8738,
    longitude: 2.2832
  },
  {
    name: 'Loft Belleville',
    address: 'Rue de Belleville, 75020 Paris',
    latitude: 48.8720,
    longitude: 2.3810
  }
]

events = []
movies.each_with_index do |movie, index|
  venue = venues_data[index % venues_data.length]

  2.times do |i|
    event_date = Date.current + (7 + i * 14).days

    event = Event.create!(
      movie: movie,
      title: "#{movie.title} - Rencontre avec #{movie.director}",
      description: "Projection exclusive suivie d'une rencontre avec #{movie.director}.",
      venue_name: venue[:name],
      venue_address: venue[:address],
      event_date: event_date,
      start_time: '20:00',
      max_capacity: 20,
      price_cents: 2500,
      latitude: venue[:latitude],
      longitude: venue[:longitude],
      status: 'upcoming'
    )
    events << event
  end
end

# Create participations
events.each do |event|
  5.times do
    user = regular_users.sample
    next if Participation.exists?(user: user, event: event)

    Participation.create!(
      user: user,
      event: event,
      status: 'confirmed',
      stripe_payment_id: "pi_#{SecureRandom.alphanumeric(24)}"
    )
  end
end

puts "Seed completed: #{User.count} users, #{Movie.count} movies, #{Event.count} events"

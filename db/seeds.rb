# Clear existing data
puts "Cleaning database..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
Creator.destroy_all
User.destroy_all

puts "Creating users..."

# Admin user
admin = User.create!(
  email: 'admin@cineroom.com',
  password: 'password123',
  first_name: 'Admin',
  last_name: 'CineRoom',
  role: :admin
)

# Regular users
users = []
10.times do
  users << User.create!(
    email: Faker::Internet.email,
    password: 'password123',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    role: :user
  )
end

puts "Created #{User.count} users"

# Creators
puts "Creating creators..."

creators = []
5.times do
  creator_user = User.create!(
    email: Faker::Internet.email,
    password: 'password123',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    role: :user
  )

  creators << Creator.create!(
    user: creator_user,
    bio: Faker::Lorem.paragraph(sentence_count: 4),
    status: :verified,
    verified_at: Faker::Time.between(from: 6.months.ago, to: Time.current)
  )
end

puts "Created #{Creator.count} creators"

# Movies
puts "Creating movies..."

genres = [ 'Drama', 'Comedy', 'Thriller', 'Documentary', 'Romance', 'Action' ]
movies = []

15.times do
  movies << Movie.create!(
    title: Faker::Movie.title,
    synopsis: Faker::Lorem.paragraph(sentence_count: 6),
    director: "#{Faker::Name.first_name} #{Faker::Name.last_name}",
    duration: rand(80..180),
    genre: genres.sample,
    language: 'fr',
    year: rand(2020..2024),
    trailer_url: "https://youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}",
    poster_url: "https://picsum.photos/400/600?random=#{rand(1000)}",
    creator: creators.sample,
    validation_status: :approved,
    validated_by: admin,
    validated_at: Faker::Time.between(from: 3.months.ago, to: Time.current)
  )
end

puts "Created #{Movie.count} movies"

# Events
puts "Creating events..."

venues = [
  { name: 'Galerie Marais', address: '15 rue des Rosiers, 75004 Paris' },
  { name: 'Rooftop République', address: 'Place République, 75011 Paris' },
  { name: 'Mansion 16e', address: 'Avenue Foch, 75016 Paris' },
  { name: 'Loft Belleville', address: 'Rue de Belleville, 75020 Paris' },
  { name: 'Studio Bastille', address: 'Place de la Bastille, 75012 Paris' }
]

events = []
20.times do
  venue = venues.sample
  event_date = Faker::Date.between(from: Date.current, to: 3.months.from_now)

  events << Event.create!(
    movie: movies.sample,
    title: "Projection privée - #{Faker::Lorem.words(number: 2).join(' ').titleize}",
    description: Faker::Lorem.paragraph(sentence_count: 3),
    venue_name: venue[:name],
    venue_address: venue[:address],
    event_date: event_date,
    start_time: [ '19:00', '19:30', '20:00', '20:30', '21:00' ].sample,
    max_capacity: rand(15..30),
    price_cents: [ 2500, 3000, 3500, 4000, 4500 ].sample,
    status: :upcoming
  )
end

puts "Created #{Event.count} events"

# Participations
puts "Creating participations..."

participations = []
events.each do |event|
  # Random number of participants (50-90% capacity)
  participants_count = rand((event.max_capacity * 0.5).to_i..(event.max_capacity * 0.9).to_i)

  selected_users = users.sample(participants_count)
  selected_users.each do |user|
    participations << Participation.create!(
      user: user,
      event: event,
      status: :confirmed,
      stripe_payment_id: "pi_#{Faker::Alphanumeric.alphanumeric(number: 24)}"
    )
  end
end

puts "Created #{Participation.count} participations"

# Reviews for past events
puts "Creating reviews..."

# Mark some events as completed
past_events = events.sample(8)
past_events.each do |event|
  event.update!(
    status: :completed,
    event_date: Faker::Date.between(from: 2.months.ago, to: 1.week.ago)
  )

  # Add reviews for participants of completed events
  event.participations.confirmed.sample(rand(2..5)).each do |participation|
    Review.create!(
      user: participation.user,
      movie: event.movie,
      event: event,
      rating: rand(3..5),
      comment: Faker::Lorem.paragraph(sentence_count: 2)
    )
  end
end

puts "Created #{Review.count} reviews"

# Summary
puts "\n=== SEED SUMMARY ==="
puts "Users: #{User.count} (including #{User.admin.count} admin)"
puts "Creators: #{Creator.count}"
puts "Movies: #{Movie.count}"
puts "Events: #{Event.count}"
puts "Participations: #{Participation.count}"
puts "Reviews: #{Review.count}"
puts "\nSeed completed successfully!"

# Useful data for testing
puts "\n=== TEST CREDENTIALS ==="
puts "Admin: admin@cineroom.com / password123"
puts "Regular users: Use any generated email / password123"

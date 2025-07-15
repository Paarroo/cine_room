Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
Creator.destroy_all
User.destroy_all

admin_user = User.create!(
  email: 'admin@cineroom.com',
  password: 'password123',
  first_name: 'Admin',
  last_name: 'CinéRoom',
  role: :admin
)

test_user = User.create!(
  email: 'test@cineroom.com',
  password: 'password123',
  first_name: 'Test',
  last_name: 'User',
  role: :user
)

creator_users = 5.times.map do
  User.create!(
    email: Faker::Internet.unique.email,
    password: 'password123',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    role: :creator
  )
end

creators = creator_users.map do |user|
  Creator.create!(
    user: user,
    bio: Faker::Lorem.paragraph(sentence_count: 3),
    status: :verified,
    verified_at: Faker::Time.between(from: 2.years.ago, to: 1.year.ago)
  )
end

regular_users = 15.times.map do
  User.create!(
    email: Faker::Internet.unique.email,
    password: 'password123',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    role: :user
  )
end

movies = creators.flat_map do |creator|
  rand(2..4).times.map do
    Movie.create!(
      creator: creator,
      title: Faker::Movie.title,
      synopsis: Faker::Lorem.paragraph(sentence_count: 4),
      director: "#{creator.user.first_name} #{creator.user.last_name}",
      duration: rand(80..180),
      genre: [ 'Drame', 'Comédie', 'Thriller', 'Documentaire', 'Romance' ].sample,
      language: 'Français',
      year: rand(2020..2024),
      trailer_url: "https://youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}",
      poster_url: "https://via.placeholder.com/400x600/#{Faker::Color.hex_color.delete('#')}/ffffff?text=#{URI.encode_www_form_component(Faker::Movie.title)}",
      validation_status: :approved,
      validated_by: admin_user,
      validated_at: Faker::Time.between(from: 1.year.ago, to: 6.months.ago)
    )
  end
end

venues = [
  { name: 'Galerie Marais', address: '15 rue des Rosiers, 75004 Paris', lat: 48.8566, lng: 2.3522 },
  { name: 'Rooftop République', address: 'Place de la République, 75011 Paris', lat: 48.8676, lng: 2.3631 },
  { name: 'Hôtel Particulier', address: 'Avenue Foch, 75016 Paris', lat: 48.8738, lng: 2.2832 },
  { name: 'Loft Belleville', address: 'Rue de Belleville, 75020 Paris', lat: 48.8720, lng: 2.3810 },
  { name: 'Studio Bastille', address: 'Rue de la Bastille, 75011 Paris', lat: 48.8532, lng: 2.3698 }
]

events = movies.flat_map do |movie|
  rand(1..3).times.map do |i|
    venue = venues.sample
    Event.create!(
      movie: movie,
      title: "#{movie.title} - Rencontre avec #{movie.director}",
      description: Faker::Lorem.paragraph(sentence_count: 2),
      venue_name: venue[:name],
      venue_address: venue[:address],
      event_date: Faker::Date.between(from: 1.week.from_now, to: 3.months.from_now),
      start_time: [ '19:00', '19:30', '20:00', '20:30', '21:00' ].sample,
      max_capacity: rand(15..30),
      price_cents: rand(20..40) * 100,
      latitude: venue[:lat],
      longitude: venue[:lng],
      status: :upcoming
    )
  end
end

events.each do |event|
  participants_count = rand(5..15)
  available_users = (regular_users + [ test_user ]).sample(participants_count)

  available_users.each do |user|
    Participation.create!(
      user: user,
      event: event,
      status: :confirmed,
      stripe_payment_id: "pi_#{Faker::Alphanumeric.alphanumeric(number: 24)}"
    )
  end
end

completed_events = Event.where('event_date < ?', 1.week.ago).limit(5)
completed_events.update_all(status: :completed)

completed_events.each do |event|
  event.participations.confirmed.sample(rand(2..5)).each do |participation|
    Review.create!(
      user: participation.user,
      movie: event.movie,
      event: event,
      rating: rand(3..5),
      comment: Faker::Lorem.paragraph(sentence_count: rand(2..4))
    )
  end
end

puts "Created #{User.count} users, #{Creator.count} creators, #{Movie.count} movies, #{Event.count} events, #{Participation.count} participations, #{Review.count} reviews"

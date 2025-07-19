Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all

User.connection.execute("TRUNCATE TABLE users RESTART IDENTITY CASCADE")

Faker::Internet.unique.clear

test_user = User.create!(
  email: 'test@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Test',
  last_name: 'User',
  role: 'user',
  bio: 'Utilisateur de test'
)

admin = User.create!(
  email: 'admin@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'CinéRoom',
  role: 'admin',
  bio: 'Administrateur de la plateforme CinéRoom'
)

admins = []
3.times do |i|
  admins << User.create!(
    email: "admin#{i+1}@cineroom.com",
    password: 'password123',
    password_confirmation: 'password123',
    first_name: "Admin#{i+1}",
    last_name: 'CinéRoom',
    role: 'admin',
    bio: "Administrateur #{i+1} de la plateforme CinéRoom"
  )
end

creators = []
5.times do |i|
  creators << User.create!(
    email: "creator#{i+1}@cineroom.com",
    password: 'password123',
    password_confirmation: 'password123',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    role: 'user',
    bio: "Passionné de cinéma indépendant, je crée des films depuis #{rand(2..15)} ans."
  )
end

regular_users = []
15.times do |i|
  regular_users << User.create!(
    email: "user#{i+1}@cineroom.com",
    password: 'password123',
    password_confirmation: 'password123',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    role: 'user',
    bio: Faker::Lorem.paragraph(sentence_count: 3)
  )
end

movies = []
creators.each do |creator|
  rand(2..4).times do
    validation_status = [ 'pending', 'approved', 'rejected' ].sample
    movie = Movie.new
    movie.creator_id = creator.id
    movie.title = Faker::Movie.title
    movie.synopsis = Faker::Lorem.paragraph(sentence_count: 5)
    movie.director = Faker::Name.name
    movie.duration = rand(80..180)
    movie.genre = [ 'Drame', 'Comédie', 'Thriller', 'Documentaire', 'Science-Fiction' ].sample
    movie.language = [ 'fr', 'en', 'es' ].sample
    movie.year = rand(2015..2024)
    movie.trailer_url = "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alpha(number: 11)}"
    movie.poster_url = Faker::LoremFlickr.image(size: "300x450", search_terms: [ 'movie' ])
    movie.validation_status = validation_status
    movie.validated_by = (validation_status != 'pending' ? [ admin, *admins ].sample : nil)
    movie.validated_at = (validation_status != 'pending' ? rand(1.month.ago..Time.current) : nil)
    movie.save!(validate: false)
    movies << movie
  end
end

approved_movies = movies.select { |movie| movie.validation_status == 'approved' }

events = approved_movies.flat_map do |movie|
  FactoryBot.create_list(:event, rand(1..3), movie: movie)
end

events.each do |event|
  participants_count = rand(5..15)
  available_users = (regular_users + [ test_user ]).sample(participants_count)
  available_users.each do |user|
    unless Participation.exists?(user: user, event: event)
      FactoryBot.create(:participation, user: user, event: event)
    end
  end
end

completed_events = Event.where('event_date < ?', 1.week.ago).limit(5)
completed_events.update_all(status: :completed)

completed_events.each do |event|
  confirmed_participations = event.participations.where(status: :confirmed)
  confirmed_participations.sample(rand(2..5)).each do |participation|
    FactoryBot.create(:review,
      user: participation.user,
      movie: event.movie,
      event: event
    )
  end
end

puts "Created #{User.count} users, #{Movie.count} movies, #{Event.count} events, #{Participation.count} participations, #{Review.count} reviews"

if Rails.env.development?
 Review.destroy_all
 Participation.destroy_all
 Event.destroy_all
 Movie.destroy_all
 Creator.destroy_all
 User.destroy_all
end

admin = User.new(
 email: 'admin@cineroom.com',
 password: 'password123',
 password_confirmation: 'password123',
 first_name: 'Admin',
 last_name: 'CinéRoom'
)
admin.role = 'admin'
admin.save!

users = []
user_data = [
 { first_name: 'Marie', last_name: 'Martin', email: 'marie@example.com' },
 { first_name: 'Pierre', last_name: 'Dubois', email: 'pierre@example.com' },
 { first_name: 'Sophie', last_name: 'Leroy', email: 'sophie@example.com' },
 { first_name: 'Lucas', last_name: 'Bernard', email: 'lucas@example.com' },
 { first_name: 'Emma', last_name: 'Petit', email: 'emma@example.com' }
]

user_data.each do |data|
 user = User.new(
   email: data[:email],
   password: 'password123',
   password_confirmation: 'password123',
   first_name: data[:first_name],
   last_name: data[:last_name]
 )
 user.role = 'user'
 user.save!
 users << user
end

creator_users_data = [
 { email: 'claire.martin@example.com', first_name: 'Claire', last_name: 'Martin' },
 { email: 'marc.dubois@example.com', first_name: 'Marc', last_name: 'Dubois' },
 { email: 'sophie.real@example.com', first_name: 'Sophie', last_name: 'Leroy' }
]

creators = []
creator_users_data.each do |data|
 user = User.new(
   email: data[:email],
   password: 'password123',
   password_confirmation: 'password123',
   first_name: data[:first_name],
   last_name: data[:last_name]
 )
 user.role = 'user'
 user.save!

 creator = Creator.create!(
   user: user,
   bio: "Bio du créateur #{data[:first_name]} #{data[:last_name]}",
   status: 'verified',
   verified_at: Time.current
 )
 creators << creator
end

movies_data = [
 {
   creator: creators[0],
   title: "Le Souffle",
   synopsis: "Un drame intimiste sur les relations intergénérationnelles.",
   director: "Claire Martin",
   duration: 95,
   genre: "Drame",
   language: "fr",
   year: 2024,
   validation_status: 'approved',
   validated_by: admin,
   validated_at: Time.current
 },
 {
   creator: creators[1],
   title: "Fragments",
   synopsis: "Documentaire sur les artistes de rue parisiens.",
   director: "Marc Dubois",
   duration: 108,
   genre: "Documentaire",
   language: "fr",
   year: 2024,
   validation_status: 'approved',
   validated_by: admin,
   validated_at: Time.current
 },
 {
   creator: creators[2],
   title: "L'Aube",
   synopsis: "Comédie romantique moderne dans la campagne française.",
   director: "Sophie Leroy",
   duration: 87,
   genre: "Comédie",
   language: "fr",
   year: 2024,
   validation_status: 'approved',
   validated_by: admin,
   validated_at: Time.current
 }
]

movies = []
movies_data.each do |movie_data|
 movie = Movie.create!(movie_data)
 movies << movie
end

events_data = [
 {
   movie: movies[0],
   title: "Projection Exclusive - Le Souffle",
   description: "Rencontrez Claire Martin après la projection pour une discussion exclusive sur son processus créatif.",
   venue_name: "Galerie Marais",
   venue_address: "15 rue des Rosiers, 75004 Paris",
   event_date: Date.current + 7.days,
   start_time: Time.parse("20:00"),
   max_capacity: 15,
   price_cents: 2500,
   status: 'upcoming',
   latitude: 48.8572,
   longitude: 2.3623
 },
 {
   movie: movies[1],
   title: "Soirée Documentaire - Fragments",
   description: "Découvrez l'univers du documentaire social avec Marc Dubois. Débat et échanges avec le public.",
   venue_name: "Rooftop République",
   venue_address: "Place République, 75011 Paris",
   event_date: Date.current + 14.days,
   start_time: Time.parse("19:30"),
   max_capacity: 25,
   price_cents: 3000,
   status: 'upcoming',
   latitude: 48.8673,
   longitude: 2.3634
 },
 {
   movie: movies[2],
   title: "Avant-Première - L'Aube",
   description: "Avant-première exclusive dans un cadre prestigieux. Cocktail offert et rencontre avec Sophie Leroy.",
   venue_name: "Hôtel Particulier 16e",
   venue_address: "Avenue Foch, 75016 Paris",
   event_date: Date.current + 21.days,
   start_time: Time.parse("20:15"),
   max_capacity: 20,
   price_cents: 4500,
   status: 'upcoming',
   latitude: 48.8719,
   longitude: 2.2885
 },
 {
   movie: movies[0],
   title: "Rétrospective - Le Souffle",
   description: "Projection de ce film remarqué au Festival de Cannes dans un loft d'exception.",
   venue_name: "Loft Belleville",
   venue_address: "Rue de Belleville, 75020 Paris",
   event_date: Date.current - 5.days,
   start_time: Time.parse("21:00"),
   max_capacity: 15,
   price_cents: 3200,
   status: 'completed',
   latitude: 48.8721,
   longitude: 2.3828
 }
]

events = []
events_data.each do |event_data|
 event = Event.create!(event_data)
 events << event
end

upcoming_events = events.select { |e| e.status == 'upcoming' }
completed_events = events.select { |e| e.status == 'completed' }

users.first(3).each do |user|
 upcoming_events.sample(2).each do |event|
   Participation.create!(
     user: user,
     event: event,
     status: 'confirmed',
     stripe_payment_id: "pi_test_#{SecureRandom.hex(8)}"
   )
 end
end

users.each do |user|
 completed_events.each do |event|
   next if rand > 0.7

   Participation.create!(
     user: user,
     event: event,
     status: 'confirmed',
     stripe_payment_id: "pi_test_#{SecureRandom.hex(8)}"
   )
 end
end

completed_events.each do |event|
 event.participations.where(status: 'confirmed').sample(rand(1..2)).each do |participation|
   Review.create!(
     user: participation.user,
     movie: event.movie,
     event: event,
     rating: rand(4..5),
     comment: [
       "Excellente soirée ! Le film était captivant et la rencontre avec le réalisateur très enrichissante.",
       "Une expérience unique dans un lieu magnifique. Je recommande vivement CinéRoom !",
       "Film touchant et discussion passionnante. L'ambiance intimiste était parfaite.",
       "Très belle découverte cinématographique. Le cadre était exceptionnel.",
       "Soirée mémorable ! J'ai adoré pouvoir échanger avec l'équipe du film."
     ].sample
   )
 end
end

puts "Nettoyage..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
Creator.destroy_all
User.destroy_all

puts "Création users..."
admin = FactoryBot.create(:user, :admin,
 email: "admin@cineroom.com",
 first_name: "Admin",
 last_name: "CinéRoom"
)

users = FactoryBot.create_list(:user, 8)

puts "Création creators..."
creators = []
users.sample(5).each do |user|
 creators << FactoryBot.create(:creator,
   user: user,
   status: :verified,
   verified_at: Faker::Time.between(from: 1.year.ago, to: 1.month.ago)
 )
end

puts "Création films..."
movies = []
creators.each do |creator|
 rand(1..3).times do
   movies << FactoryBot.create(:movie,
     creator: creator,
     validation_status: :approved,
     validated_by: admin,
     validated_at: Faker::Time.between(from: 6.months.ago, to: 1.week.ago)
   )
 end
end

puts "Création événements..."
events = []
movies.each do |movie|
 rand(1..2).times do
   events << FactoryBot.create(:event, movie: movie)
 end
end

puts "Création réservations..."
events.each do |event|
 available_users = users - [ event.movie.creator.user ]
 available_users.sample(rand(1..3)).each do |user|
   FactoryBot.create(:participation, user: user, event: event)
 end
end

puts "Création avis..."
past_events = events.select { |e| e.event_date < Date.current }
past_events.each do |event|
 event.participations.sample(rand(0..2)).each do |participation|
   FactoryBot.create(:review,
     user: participation.user,
     movie: event.movie,
     event: event
   )
 end
end

puts "Seed terminé !"
puts "Données créées :"
puts "   #{User.count} utilisateurs"
puts "   #{Creator.count} créateurs"
puts "   #{Movie.count} films"
puts "   #{Event.count} événements"
puts "   #{Participation.count} réservations"
puts "   #{Review.count} avis"

puts "Compte admin :"
puts "   Email: admin@cineroom.com"
puts "   Password: password123"

puts "Creators :"
Creator.includes(:user).each do |creator|
 puts "   #{creator.user.full_name} (#{creator.user.email})"
end

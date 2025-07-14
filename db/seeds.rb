puts "🗑️ Nettoyage..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
User.destroy_all

puts "👥 Création users avec FactoryBot..."
admin = FactoryBot.create(:user, :admin,
  email: "admin@cineroom.com",
  first_name: "Admin",
  last_name: "CinéRoom"
)

users = FactoryBot.create_list(:user, 3)

puts "🎬 Création films..."
movies = FactoryBot.create_list(:movie, 3)

puts "📅 Création événements..."
events = []
movies.each do |movie|
  rand(1..2).times do
    events << FactoryBot.create(:event, movie: movie)
  end
end

puts "🎫 Création réservations..."
events.each do |event|
  users.sample(rand(1..2)).each do |user|
    FactoryBot.create(:participation, user: user, event: event)
  end
end

puts "⭐ Création avis..."
past_events = events.select { |e| e.event_date < Date.current }
past_events.each do |event|
  event.participations.sample(1).each do |participation|
    FactoryBot.create(:review,
      user: participation.user,
      movie: event.movie,
      event: event
    )
  end
end

puts "✅ Seed terminé !"
puts "📊 Données créées :"
puts "   • #{User.count} utilisateurs"
puts "   • #{Movie.count} films"
puts "   • #{Event.count} événements"
puts "   • #{Participation.count} réservations"
puts "   • #{Review.count} avis"

puts "\n🔑 Compte admin :"
puts "   Email: admin@cineroom.com"
puts "   Password: password123"

puts "\n👤 Autres users :"
User.where.not(role: 1).each do |user|
  puts "   #{user.email} / password123"
end

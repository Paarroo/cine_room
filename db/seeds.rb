# db/seeds.rb
# Clear existing data
puts "🗑️  Nettoyage des données existantes..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
User.destroy_all

puts "🏭 Création des factories avec FactoryBot..."

# Create Users (regular users + future admin)
puts "👥 Création des utilisateurs..."
users = FactoryBot.create_list(:user, 15)
puts "✅ #{users.count} utilisateurs créés"

# Create Movies
puts "🎬 Création des films..."
movies = FactoryBot.create_list(:movie, 12)
puts "✅ #{movies.count} films créés"

# Create Events
puts "📅 Création des événements..."
events = []
movies.each do |movie|
  # 1-3 événements par film
  rand(1..3).times do
    events << FactoryBot.create(:event, movie: movie)
  end
end
puts "✅ #{events.count} événements créés"

# Create Participations
puts "🎫 Création des réservations..."
participations = []
events.each do |event|
  # Réserver entre 30% et 90% de la capacité
  participants_count = rand((event.max_capacity * 0.3).to_i..(event.max_capacity * 0.9).to_i)

  users.sample(participants_count).each do |user|
    # Éviter les doublons user/event
    unless event.participations.where(user: user).exists?
      participations << FactoryBot.create(:participation, user: user, event: event)
    end
  end
end
puts "✅ #{participations.count} réservations créées"

# Create Reviews (seulement pour événements passés)
puts "⭐ Création des avis..."
past_events = events.select { |event| event.event_date < Date.current }
reviews = []

past_events.each do |event|
  # 40-80% des participants laissent un avis
  participants = event.participations.includes(:user)
  reviewers_count = rand((participants.count * 0.4).to_i..(participants.count * 0.8).to_i)

  participants.sample(reviewers_count).each do |participation|
    reviews << FactoryBot.create(:review,
      user: participation.user,
      movie: event.movie,
      event: event
    )
  end
end
puts "✅ #{reviews.count} avis créés"

puts "\n🎉 SEED TERMINÉ !"
puts "📊 Statistiques finales :"
puts "   • #{User.count} utilisateurs"
puts "   • #{Movie.count} films"
puts "   • #{Event.count} événements"
puts "   • #{Participation.count} réservations"
puts "   • #{Review.count} avis"

# Destroy existing data in development
if Rails.env.development?
  puts "🗑️  Cleaning database..."
  Review.destroy_all
  Participation.destroy_all
  Event.destroy_all
  Movie.destroy_all
  User.destroy_all
  puts "✅ Database cleaned!"
end

puts "🌱 Starting seeds..."

# Create admin user
puts "👑 Creating admin..."
admin = FactoryBot.create(:user, :admin)
puts "✅ Admin created: #{admin.email}"

# Create regular users (20)
puts "👥 Creating users..."
users = FactoryBot.create_list(:user, 20)
puts "✅ #{users.count} users created"

# Create creator users (10)
puts "🎬 Creating creators..."
creators = FactoryBot.create_list(:user, 10, :creator)
puts "✅ #{creators.count} creators created"

# Create movies (30)
puts "🎭 Creating movies..."
movies = []

# Validated movies (20)
validated_movies = FactoryBot.create_list(:movie, 20, :validated) do |movie|
  movie.validated_by = admin
  movie.user = creators.sample
end
movies += validated_movies

# Pending movies (7)
pending_movies = FactoryBot.create_list(:movie, 7, :pending) do |movie|
  movie.user = creators.sample
end
movies += pending_movies

# Rejected movies (3)
rejected_movies = FactoryBot.create_list(:movie, 3, :rejected) do |movie|
  movie.validated_by = admin
  movie.user = creators.sample
end
movies += rejected_movies

puts "✅ #{movies.count} movies created (#{validated_movies.count} validated, #{pending_movies.count} pending, #{rejected_movies.count} rejected)"

# Create events (40) - only for validated movies
puts "📅 Creating events..."
events = []

validated_movies.each do |movie|
  # 1-3 events per validated movie
  movie_events = FactoryBot.create_list(:event, rand(1..3)) do |event|
    event.movie = movie
    event.title = "Projection de #{movie.title}"
  end
  events += movie_events
end

puts "✅ #{events.count} events created"

# Create participations (100)
puts "🎫 Creating participations..."
all_users = users + creators
participations = []

events.each do |event|
  # 1-8 participations per event
  event_participations = FactoryBot.create_list(:participation, rand(1..8)) do |participation|
    participation.event = event
    participation.user = all_users.sample

    # Ensure unique user per event
    existing_users = event.participations.pluck(:user_id)
    available_users = all_users.reject { |u| existing_users.include?(u.id) }
    participation.user = available_users.sample if available_users.any?
  end
  participations += event_participations
end

puts "✅ #{participations.count} participations created"

# Create reviews (60) - only for completed events with confirmed participations
puts "⭐ Creating reviews..."
completed_participations = Participation.joins(:event)
                                      .where(events: { status: :completed }, status: :confirmed)
                                      .includes(:user, :event, event: :movie)

reviews = completed_participations.sample(60).map do |participation|
  FactoryBot.create(:review) do |review|
    review.user = participation.user
    review.movie = participation.event.movie
    review.event = participation.event
  end
end

puts "✅ #{reviews.count} reviews created"

# Final statistics
puts "\n📊 FINAL STATISTICS:"
puts "👑 Admins: #{User.where(role: :admin).count}"
puts "👥 Users: #{User.where(role: :user).count}"
puts "🎬 Total creators (users with movies): #{User.joins(:movies).distinct.count}"
puts "🎭 Movies: #{Movie.count} (✅#{Movie.where(validation_status: :validated).count} validated, ⏳#{Movie.where(validation_status: :pending).count} pending, ❌#{Movie.where(validation_status: :rejected).count} rejected)"
puts "📅 Events: #{Event.count} (🔜#{Event.where(status: :upcoming).count} upcoming, ✅#{Event.where(status: :completed).count} completed, 🔥#{Event.where(status: :sold_out).count} sold out)"
puts "🎫 Participations: #{Participation.count} (✅#{Participation.where(status: :confirmed).count} confirmed, ⏳#{Participation.where(status: :pending).count} pending, ❌#{Participation.where(status: :cancelled).count} cancelled)"
puts "⭐ Reviews: #{Review.count}"
puts "💰 Total Revenue: #{Participation.joins(:event).where(status: :confirmed).sum('events.price_cents * participations.seats') / 100.0}€"

puts "\n🎉 Seeds completed successfully!"
puts "🔑 Admin login: #{admin.email} / password123"

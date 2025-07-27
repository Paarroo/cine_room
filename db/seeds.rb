require 'faker'
require 'factory_bot_rails'

puts "🎬 Seeding CinéRoom database with FactoryBot & Faker..."

# Production optimizations
if Rails.env.production?
  puts "🔧 Production mode - optimizing seed process..."
  
  # Enable seed mode to skip poster validation
  Rails.application.config.seed_in_progress = true
  
  # Disable movie validations for seeding
  Movie.skip_callback(:validate, :before, :authorship_must_be_confirmed)
  
  # Disable welcome email during seeding
  User.skip_callback(:create, :after, :send_welcome_email)
  
  # Disable ActionMailer deliveries during seeding
  ActionMailer::Base.perform_deliveries = false
  
  # Disable ActiveJob completely during seeding
  original_queue_adapter = ActiveJob::Base.queue_adapter
  ActiveJob::Base.queue_adapter = :test
  
  # Mark as seed in progress to skip avatar attachment
  Rails.application.config.seed_in_progress = true
end

# Clean database
puts "🧹 Cleaning database..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
User.destroy_all

# Create admin
puts "👑 Creating admin user..."
admin = FactoryBot.create(:user, :admin,
  email: 'admin@cineroom.com',
  first_name: 'Admin',
  last_name: 'CinéRoom',
  password: 'password123',
  password_confirmation: 'password123'
)

# Create regular users with favorites
puts "👥 Creating 15 regular users..."
regular_users = FactoryBot.create_list(:user, 15)

# Create creators
puts "🎭 Creating 8 creators..."
creators = FactoryBot.create_list(:user, 8, :creator)

# Create approved movies for creators
puts "🎥 Creating approved movies..."
approved_movies = []
creators.each do |creator|
  movies = FactoryBot.create_list(:movie, rand(2..5), :approved, user: creator)
  approved_movies.concat(movies)
end

# Create pending movies
puts "⏳ Creating pending movies for validation..."
creators.sample(4).each do |creator|
  FactoryBot.create_list(:movie, rand(1..3), user: creator)
end

# Create rejected movies
puts "❌ Creating some rejected movies..."
creators.sample(3).each do |creator|
  FactoryBot.create_list(:movie, rand(1..2), :rejected, user: creator, validated_by: admin)
end

# Create events for approved movies
puts "🎪 Creating events..."
upcoming_events = []
finished_events = []
ongoing_events = []

approved_movies.each do |movie|
  # Upcoming events
  rand(1..4).times do
    event = FactoryBot.create(:event, :upcoming, movie: movie)
    upcoming_events << event
  end
  
  # Finished events (with reviews)
  if [true, false, true].sample # 66% chance
    rand(1..3).times do
      event = FactoryBot.create(:event, :finished, movie: movie)
      finished_events << event
    end
  end
  
  # Ongoing events (happening now)
  if [true, false, false].sample # 33% chance
    event = FactoryBot.create(:event, :ongoing, movie: movie)
    ongoing_events << event
  end
end

# Create sold out events
puts "🎫 Creating sold out events..."
Event.upcoming.sample(rand(3..6)).each do |event|
  event.update!(status: :sold_out)
end

# Create participations
puts "👫 Creating participations..."
Event.all.each do |event|
  next if event.sold_out?

  participants_count = case event.status
  when 'upcoming'
    rand(1..8)
  when 'finished'
    rand(5..12)
  when 'ongoing'
    rand(3..10)
  when 'sold_out'
    event.max_capacity
  else
    0
  end

  participants = regular_users.sample([participants_count, event.max_capacity].min)
  participants.each do |user|
    next if event.users.include?(user)

    FactoryBot.create(:participation,
      user: user,
      event: event,
      status: event.finished? ? :confirmed : [:pending, :confirmed, :confirmed].sample,
      seats: rand(1..4)
    )
  end
end

# Create reviews for finished events
puts "⭐ Creating reviews..."
finished_events.each do |event|
  event.participations.confirmed.each do |participation|
    next if rand > 0.8 # 80% chance de laisser un avis

    FactoryBot.create(:review,
      user: participation.user,
      event: event,
      movie: event.movie,
      rating: [1, 2, 3, 4, 4, 5, 5, 5].sample, # Skewed toward positive
      comment: [
        "#{Faker::Lorem.sentence(word_count: rand(8..15))} Une expérience vraiment mémorable !",
        "Excellente soirée cinéma ! #{Faker::Lorem.sentence(word_count: rand(6..12))}",
        "#{Faker::Lorem.sentence(word_count: rand(10..18))} Je recommande vivement.",
        "Film captivant, #{Faker::Lorem.sentence(word_count: rand(5..10))}",
        "Très bonne organisation. #{Faker::Lorem.sentence(word_count: rand(7..14))}",
        "#{Faker::Lorem.sentence(word_count: rand(12..20))} Parfait pour une sortie !",
        "Décevant malheureusement. #{Faker::Lorem.sentence(word_count: rand(8..15))}",
        "#{Faker::Lorem.sentence(word_count: rand(6..13))} Une belle découverte cinématographique !",
        "Ambiance chaleureuse et #{Faker::Lorem.sentence(word_count: rand(9..16))}",
        "#{Faker::Lorem.sentence(word_count: rand(11..19))} À refaire sans hésiter !"
      ].sample
    )
  end
end

# Create favorites system
puts "❤️ Creating favorites..."
regular_users.each do |user|
  # Each user favorites 0-8 movies
  favorite_count = [0, 0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8].sample
  movies_to_favorite = approved_movies.sample(favorite_count)
  
  movies_to_favorite.each do |movie|
    FactoryBot.create(:favorite, user: user, movie: movie)
  end
end

# Create more realistic participations for ongoing events
puts "🎬 Adding participations to ongoing events..."
ongoing_events.each do |event|
  additional_participants = regular_users.sample(rand(2..6))
  additional_participants.each do |user|
    next if event.users.include?(user)
    next if event.participations.count >= event.max_capacity

    FactoryBot.create(:participation,
      user: user,
      event: event,
      status: :confirmed,
      seats: rand(1..3)
    )
  end
end

# Create some cancelled participations
puts "❌ Creating cancelled participations..."
Participation.pending.sample(rand(3..8)).each do |participation|
  participation.update!(status: :cancelled)
end

# Additional diversity: create users with different engagement levels
puts "🎯 Creating diverse user engagement..."

# Power users (heavy favorites and participations)
2.times do
  power_user = FactoryBot.create(:user)
  # Lots of favorites
  approved_movies.sample(rand(15..25)).each do |movie|
    FactoryBot.create(:favorite, user: power_user, movie: movie) unless movie.favorited_by?(power_user)
  end
  # Lots of participations
  Event.upcoming.sample(rand(3..6)).each do |event|
    next if event.users.include?(power_user) || event.sold_out?
    FactoryBot.create(:participation, user: power_user, event: event, status: :confirmed, seats: rand(1..2))
  end
end

# Inactive users (no participations or favorites)
3.times do
  FactoryBot.create(:user)
end

# Re-enable production settings
if Rails.env.production?
  puts "🔄 Re-enabling production settings..."
  
  # Disable seed mode
  Rails.application.config.seed_in_progress = false
  
  # Re-enable movie validations for live app
  Movie.set_callback(:validate, :before, :authorship_must_be_confirmed)
  
  # Re-enable welcome email callback
  User.set_callback(:create, :after, :send_welcome_email)
  
  # Re-enable ActionMailer deliveries
  ActionMailer::Base.perform_deliveries = true
  
  # Restore original queue adapter
  ActiveJob::Base.queue_adapter = original_queue_adapter
  
  # Remove seed in progress flag
  Rails.application.config.seed_in_progress = false
end

puts "✅ Database seeded successfully!"
puts ""
puts "📊 Summary:"
puts "  👥 Users: #{User.count} (#{User.where(role: 'admin').count} admin, #{User.where(role: 'creator').count} creators, #{User.where(role: 'user').count} users)"
puts "  🎥 Movies: #{Movie.count} (#{Movie.approved.count} approved, #{Movie.pending.count} pending, #{Movie.rejected.count} rejected)"
puts "  🎪 Events: #{Event.count} (#{Event.upcoming.count} upcoming, #{Event.finished.count} finished, #{Event.ongoing.count} ongoing, #{Event.sold_out.count} sold out)"
puts "  🎫 Participations: #{Participation.count} (#{Participation.confirmed.count} confirmed, #{Participation.pending.count} pending, #{Participation.cancelled.count} cancelled)"
puts "  ⭐ Reviews: #{Review.count}"
puts "  ❤️  Favorites: #{Favorite.count}"
puts ""
puts "🔑 Login credentials:"
puts "  Admin: admin@cineroom.com / password123"
puts "  Test user: #{User.where(role: 'user').first.email} / password123"
puts "  Test creator: #{User.where(role: 'creator').first.email} / password123"
puts ""
puts "🎬 CinéRoom is ready to roll!"
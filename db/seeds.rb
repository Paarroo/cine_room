require 'faker'
require 'factory_bot_rails'

puts "Seeding CinéRoom database with FactoryBot & Faker..."

# Enable seed mode to skip poster validation in all environments
Rails.application.config.seed_in_progress = true

# Temporarily disable validations for seeding in all environments
Movie.class_eval do
  def authorship_must_be_confirmed
    # Skip validation during seeding
  end
end

Event.class_eval do
  def event_date_must_be_at_least_one_week_from_now
    # Skip validation during seeding
  end
end

# Production optimizations
if Rails.env.production?
  puts "Production mode - optimizing seed process..."
  
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
puts "Cleaning database..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
User.destroy_all

# Create admin
puts "Creating admin user..."
admin = FactoryBot.create(:user, :admin,
  email: 'admin@cineroom.com',
  first_name: 'Admin',
  last_name: 'CinéRoom',
  password: 'password123',
  password_confirmation: 'password123'
)

# Create regular users with favorites
puts "Creating 25 regular users..."
regular_users = FactoryBot.create_list(:user, 25)

# Create creators
puts "Creating 12 creators..."
creators = FactoryBot.create_list(:user, 12, :creator)

# Create additional test users for edge cases
puts "Creating test users for edge cases..."
test_users = [
  FactoryBot.create(:user, email: 'user.test@example.com', first_name: 'User', last_name: 'Test', confirmed_at: Time.current),
  FactoryBot.create(:user, :creator, email: 'creator.test@example.com', first_name: 'Creator', last_name: 'Test', confirmed_at: Time.current),
  FactoryBot.create(:user, email: 'inactive.user@example.com', first_name: 'Inactive', last_name: 'User'),
  FactoryBot.create(:user, :creator, email: 'prolific.creator@example.com', first_name: 'Prolific', last_name: 'Creator', confirmed_at: Time.current)
]

# Create approved movies for creators
puts "Creating approved movies..."
approved_movies = []
all_creators = creators + test_users.select(&:creator?)

all_creators.each do |creator|
  movie_count = case creator.email
  when 'prolific.creator@example.com'
    rand(8..12) # Prolific creator with many movies
  else
    rand(2..5)
  end
  
  movies = FactoryBot.create_list(:movie, movie_count, :approved, user: creator)
  approved_movies.concat(movies)
end

# Create pending movies (various states for testing)
puts "Creating pending movies for validation..."
all_creators.sample(6).each do |creator|
  FactoryBot.create_list(:movie, rand(1..4), user: creator)
end

# Create rejected movies with various reasons
puts "Creating rejected movies..."
all_creators.sample(5).each do |creator|
  FactoryBot.create_list(:movie, rand(1..2), :rejected, user: creator)
end

# Create movies with specific test scenarios
puts "Creating test scenario movies..."
test_creator = test_users.find(&:creator?)
FactoryBot.create(:movie, 
  title: "Film Test Très Long Titre Pour Vérifier L'Affichage", 
  user: test_creator, 
  validation_status: :approved,
  year: 2024,
  duration: 240 # Very long movie
)

FactoryBot.create(:movie, 
  title: "Court", 
  user: test_creator, 
  validation_status: :pending,
  year: 2020,
  duration: 45 # Very short movie
)

# Create only upcoming events to avoid validation issues in production
puts "Creating upcoming events..."
upcoming_events = []
finished_events = []
ongoing_events = []
cancelled_events = []

approved_movies.each do |movie|
  # Create 1-2 upcoming events per movie
  event_count = rand(1..2)
  
  event_count.times do
    begin
      event = Event.new(
        title: "Projection de #{movie.title}",
        movie: movie,
        venue_name: ["Cinéma Rex", "Gaumont", "UGC", "MK2", "Pathé"].sample,
        venue_address: [
          "1 Boulevard Poissonnière, 75002 Paris",
          "30 Avenue d'Italie, 75013 Paris", 
          "14 Rue Lincoln, 75008 Paris",
          "128 Avenue de France, 75013 Paris",
          "19 Rue de Vaugirard, 75006 Paris"
        ].sample,
        event_date: rand(1.week.from_now..2.months.from_now).to_date,
        start_time: ['19:00', '20:30', '21:00'].sample,
        max_capacity: rand(30..80),
        price_cents: rand(1000..2000),
        status: :upcoming
      )
      
      event.save!
      upcoming_events << event
    rescue => e
      Rails.logger.error "Failed to create event for #{movie.title}: #{e.message}"
      # Skip this event and continue
    end
  end
end

# Create specific test events - all upcoming to avoid validation issues
puts "Creating test scenario events..."
if approved_movies.any?
  test_movie = approved_movies.sample

  # Event with high price
  begin
    expensive_event = Event.create!(
      movie: test_movie,
      title: "Projection Premium VIP",
      price_cents: 15000, # 150€
      max_capacity: 20,
      venue_name: "Cinéma de Luxe",
      venue_address: "1 Avenue des Champs-Élysées, 75008 Paris",
      event_date: 3.weeks.from_now.to_date,
      start_time: "20:00",
      status: :upcoming
    )
  rescue => e
    Rails.logger.error "Failed to create expensive event: #{e.message}"
  end

  # Event with low price
  begin
    cheap_event = Event.create!(
      movie: test_movie,
      title: "Séance Étudiante", 
      price_cents: 500, # 5€
      max_capacity: 80,
      venue_name: "Université Paris",
      venue_address: "21 Rue d'Assas, 75006 Paris",
      event_date: 4.weeks.from_now.to_date,
      start_time: "18:30",
      status: :upcoming
    )
  rescue => e
    Rails.logger.error "Failed to create cheap event: #{e.message}"
  end
end

# Mark some events as sold out
puts "Creating sold out events..."
begin
  upcoming_events.sample([upcoming_events.count / 4, 3].max).each do |event|
    event.update!(status: :sold_out)
  end
rescue => e
  Rails.logger.error "Failed to create sold out events: #{e.message}"
end

# Create participations for upcoming events only
puts "Creating participations..."
all_users = regular_users + test_users.reject(&:admin?)

upcoming_events.each do |event|
  next if event.sold_out?

  participants_count = rand(1..8)
  participants = all_users.sample([participants_count, event.max_capacity, all_users.count].min)
  
  participants.each do |user|
    next if event.users.include?(user)

    begin
      FactoryBot.create(:participation,
        user: user,
        event: event,
        status: :confirmed,
        seats: rand(1..3)
      )
    rescue => e
      Rails.logger.error "Failed to create participation: #{e.message}"
      # Continue with next participant
    end
  end
end

# Skip reviews creation for production seeding to avoid complexity
puts "Skipping reviews creation for production stability..."

# Create simple favorites system
puts "Creating favorites..."
regular_users.sample(10).each do |user|
  # Each selected user favorites 1-3 movies
  favorite_count = rand(1..3)
  movies_to_favorite = approved_movies.sample([favorite_count, approved_movies.count].min)
  
  movies_to_favorite.each do |movie|
    begin
      FactoryBot.create(:favorite, user: user, movie: movie)
    rescue => e
      Rails.logger.error "Failed to create favorite: #{e.message}"
      # Continue with next favorite
    end
  end
end

# Skip complex edge cases for production stability
puts "Skipping complex test scenarios for production stability..."

# Re-enable production settings
if Rails.env.production?
  puts "Re-enabling production settings..."
  
  # Disable seed mode
  Rails.application.config.seed_in_progress = false
  
  # Restore authorship validation for live app
  Movie.class_eval do
    def authorship_must_be_confirmed
      if authorship_confirmed != "1"
        errors.add(:base, "Tu dois confirmer être l'auteur ou l'autrice de cette vidéo pour pouvoir la publier.")
      end
    end
  end
  
  # Restore event date validation for live app
  Event.class_eval do
    def event_date_must_be_at_least_one_week_from_now
      if event_date < 1.week.from_now
        errors.add(:event_date, "doit être au moins une semaine après aujourd'hui")
      end
    end
  end
  
  # Re-enable welcome email callback
  User.set_callback(:create, :after, :send_welcome_email)
  
  # Re-enable ActionMailer deliveries
  ActionMailer::Base.perform_deliveries = true
  
  # Restore original queue adapter
  ActiveJob::Base.queue_adapter = original_queue_adapter
  
  # Remove seed in progress flag
  Rails.application.config.seed_in_progress = false
end

puts "Database seeded successfully!"
puts ""
puts "Summary:"
puts "  Users: #{User.count} (#{User.where(role: 'admin').count} admin, #{User.where(role: 'creator').count} creators, #{User.where(role: 'user').count} users)"
puts "  Movies: #{Movie.count} (#{Movie.approved.count} approved, #{Movie.pending.count} pending, #{Movie.rejected.count} rejected)"
puts "  Events: #{Event.count} (#{Event.upcoming.count} upcoming, #{Event.sold_out.count} sold out)"
puts "  Participations: #{Participation.count} (#{Participation.confirmed.count} confirmed)"
puts "  Favorites: #{Favorite.count}"
puts ""
puts "Login credentials:"
puts "  Admin: admin@cineroom.com / password123"
puts "  Test User: user.test@example.com / password123"
puts "  Test Creator: creator.test@example.com / password123"
puts "  Prolific Creator: prolific.creator@example.com / password123"
puts ""
puts "CinéRoom production seeding completed successfully!"
test_user = User.create!(
  email: 'test@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Jean',
  last_name: 'Cinéphile',
  role: :user
)

admin_user = User.create!(
  email: 'admin@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'CinéRoom',
  role: :admin
)

# db/seeds.rb

puts "🌱 Seeding the database..."

# Clean all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
Creator.destroy_all
User.destroy_all
AdminUser.destroy_all

# Create Users
users = FactoryBot.create_list(:user, 10)

# Create an AdminUser for ActiveAdmin
AdminUser.create!(email: "admin@cineroom.com", password: "password")

# Create Creators
creators = users.first(3).map { |user| FactoryBot.create(:creator, user: user) }

# Create Movies
movies = creators.map { |creator| FactoryBot.create(:movie, creator: creator) }

# Create Events
events = movies.map do |movie|
  FactoryBot.create(:event, movie: movie)
end

# Create Participations
users.each do |user|
  events.sample(2).each do |event|
    FactoryBot.create(:participation, user: user, event: event)
  end
end

puts "✅ Done seeding!"

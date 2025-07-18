require 'faker'

puts "🌱 Seeding the database..."

puts "Cleaning database..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
User.destroy_all

puts "Creating specific users..."

User.create!(
  email: 'test@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Jean',
  last_name: 'Cinéphile',
  role: :user
)

User.create!(
  email: 'admin@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'CinéRoom',
  role: :admin
)

User.create!(
  email: 'creator@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Créa',
  last_name: 'Testeur',
  role: :creator
)

puts "Creating random users..."

admin        = FactoryBot.create(:user, role: :admin, email: "admin@example.com")
creators     = FactoryBot.create_list(:user, 3, role: :creator)
regular_users = FactoryBot.create_list(:user, 10, role: :user)

puts "Creating approved movies for creators..."

creators.each do |creator|
  # 2 approved, 1 pending
  2.times do
    FactoryBot.create(:movie, user: creator, validation_status: :approved)
  end
  FactoryBot.create(:movie, user: creator, validation_status: :pending)
end

puts "Creating events for each approved movie..."

Movie.approved.each do |movie|
  FactoryBot.create_list(:event, 2, movie: movie)
end

puts "Creating participations and reviews..."

Event.all.each do |event|
  participants = regular_users.sample(rand(2..4))
  participants.each do |user|
    FactoryBot.create(:participation, user: user, event: event)
    FactoryBot.create(:review, user: user, event: event, movie: event.movie)
  end
end

puts "✅ Seeding complete!"

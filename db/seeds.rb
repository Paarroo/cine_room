require 'faker'
require 'factory_bot_rails'

puts " Seeding the database..."

puts "Cleaning database..."
Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
User.destroy_all

puts "Creating admin user..."
admin = FactoryBot.create(:user, :admin)

puts "Creating #{10} regular users..."
regular_users = FactoryBot.create_list(:user, 10)

puts "Creating #{5} creators..."
creators = FactoryBot.create_list(:user, 5, :creator)

puts "Creating approved movies for creators..."
approved_movies = []
creators.each do |creator|
  movies = FactoryBot.create_list(:movie, rand(2..4), :approved, user: creator, validated_by: admin)
  approved_movies.concat(movies)
end

puts "Creating pending movies for some creators..."
creators.sample(3).each do |creator|
  FactoryBot.create_list(:movie, rand(1..2), user: creator)
end

puts "Creating events for approved movies..."
approved_movies.each do |movie|
  FactoryBot.create_list(:event, rand(1..3), :upcoming, movie: movie)
  FactoryBot.create_list(:event, rand(0..2), :completed, movie: movie) if [ true, false ].sample
end

puts "Creating some sold out events..."
Event.upcoming.sample(rand(3..5)).each do |event|
  event.update!(status: :sold_out)
end

puts "Creating participations for events..."
Event.all.each do |event|
  next if event.sold_out?

  participants_count = case event.status
  when 'upcoming'
    rand(1..5)
  when 'completed'
    rand(3..8)
  when 'sold_out'
    event.max_capacity
  else
    0
  end

  participants = regular_users.sample(participants_count)
  participants.each do |user|
    next if event.users.include?(user)

    participation = FactoryBot.create(:participation,
      user: user,
      event: event,
      status: event.completed? ? :confirmed : [ :pending, :confirmed ].sample,
      seats: rand(1..3)
    )
  end
end

puts "Creating reviews for completed events..."
Event.completed.each do |event|
  event.participations.confirmed.each do |participation|
    next if rand > 0.7 # 70% chance de laisser un avis

    FactoryBot.create(:review,
      user: participation.user,
      event: event,
      movie: event.movie,
      rating: rand(1..5),
      comment: [
        "Excellente soirée cinéma ! #{Faker::Lorem.sentence}",
        "Une expérience inoubliable. #{Faker::Lorem.sentence}",
        "Film intéressant, mais #{Faker::Lorem.sentence}",
        "Décevant malheureusement. #{Faker::Lorem.sentence}",
        "Parfait pour une sortie entre amis ! #{Faker::Lorem.sentence}"
      ].sample
    )
  end
end

puts " Database seeded successfully!"
puts "Created:"
puts "  Users: #{User.count} (#{User.admin_users.count} admin, #{User.creators.count} creators, #{User.regular_users.count} users)"
puts "  Movies: #{Movie.count} (#{Movie.approved.count} approved, #{Movie.pending.count} pending)"
puts "  Events: #{Event.count} (#{Event.upcoming.count} upcoming, #{Event.completed.count} completed, #{Event.sold_out.count} sold out)"
puts "  Participations: #{Participation.count} (#{Participation.confirmed.count} confirmed)"
puts " Reviews: #{Review.count}"
puts " Seeding complete!"

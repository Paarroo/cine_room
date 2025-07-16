Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
Creator.destroy_all
User.destroy_all

test_user = FactoryBot.create(:user, email: 'test@cineroom.com')

creators = FactoryBot.create_list(:creator, 5)

regular_users = FactoryBot.create_list(:user, 15)

movies = creators.flat_map do |creator|
  FactoryBot.create_list(:movie, rand(2..4), creator: creator)
end

events = movies.flat_map do |movie|
  FactoryBot.create_list(:event, rand(1..3), movie: movie)
end

events.each do |event|
  participants_count = rand(5..15)
  available_users = (regular_users + [ test_user ]).sample(participants_count)

  available_users.each do |user|
    FactoryBot.create(:participation, user: user, event: event)
  end
end

completed_events = Event.where('event_date < ?', 1.week.ago).limit(5)
completed_events.update_all(status: :completed)

completed_events.each do |event|
  event.participations.confirmed.sample(rand(2..5)).each do |participation|
    FactoryBot.create(:review,
      user: participation.user,
      movie: event.movie,
      event: event
    )
  end
end

AdminUser.create!(
  email: 'admin@cineroom.com',
  password: 'password123',
  status: 'active'
)

puts "Created #{User.count} users, #{Creator.count} creators, #{Movie.count} movies, #{Event.count} events, #{Participation.count} participations, #{Review.count} reviews, 1 admin"

test_user = User.create!(
  email: 'test@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Jean',
  last_name: 'Cinéphile',
  role: :user
)



Participation.destroy_all
Event.destroy_all
Movie.destroy_all
Creator.destroy_all
User.destroy_all


users = FactoryBot.create_list(:user, 10)


AdminUser.create!(email: "admin@cineroom.com", password: "password")


creators = users.first(3).map { |user| FactoryBot.create(:creator, user: user) }

movies = creators.map { |creator| FactoryBot.create(:movie, creator: creator) }

events = movies.map do |movie|
  FactoryBot.create(:event, movie: movie)
end

users.each do |user|
  events.sample(2).each do |event|
    FactoryBot.create(:participation, user: user, event: event)
  end
end

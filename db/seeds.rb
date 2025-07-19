Review.destroy_all
Participation.destroy_all
Event.destroy_all
Movie.destroy_all
User.destroy_all

test_user = FactoryBot.create(:user, email: 'test@cineroom.com')
admin = FactoryBot.create(:admin)
admins = FactoryBot.create_list(:admin, 3)
creators = FactoryBot.create_list(:user, 5, :creator)
regular_users = FactoryBot.create_list(:user, 15)

movies = creators.flat_map do |creator|
  rand(2..4).times.map do
    validation_status = ['pending', 'approved', 'rejected'].sample
    movie = Movie.create!(
      creator_id: creator.id,
      title: Faker::Movie.title,
      synopsis: Faker::Lorem.paragraph(sentence_count: 5),
      director: Faker::Name.name,
      duration: rand(80..180),
      genre: ['Drame', 'Comédie', 'Thriller', 'Documentaire', 'Science-Fiction'].sample,
      language: ['fr', 'en', 'es'].sample,
      year: rand(2015..2024),
      trailer_url: "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alpha(number: 11)}",
      poster_url: Faker::LoremFlickr.image(size: "300x450", search_terms: ['movie']),
      validation_status: validation_status,
      validated_by: (validation_status != 'pending' ? [admin, *admins].sample : nil),
      validated_at: (validation_status != 'pending' ? rand(1.month.ago..Time.current) : nil)
    )
    movie
  end
end.flatten

approved_movies = movies.select { |movie| movie.validation_status == 'approved' }

events = approved_movies.flat_map do |movie|
  FactoryBot.create_list(:event, rand(1..3), movie: movie)
end

events.each do |event|
  participants_count = rand(5..15)
  available_users = (regular_users + [test_user]).sample(participants_count)
  available_users.each do |user|
    unless Participation.exists?(user: user, event: event)
      FactoryBot.create(:participation, user: user, event: event)
    end
  end
end

completed_events = Event.where('event_date < ?', 1.week.ago).limit(5)
completed_events.update_all(status: :completed)

completed_events.each do |event|
  confirmed_participations = event.participations.where(status: :confirmed)
  confirmed_participations.sample(rand(2..5)).each do |participation|
    FactoryBot.create(:review,
      user: participation.user,
      movie: event.movie,
      event: event
    )
  end
end

puts "Created #{User.count} users, #{Movie.count} movies, #{Event.count} events, #{Participation.count} participations, #{Review.count} reviews"


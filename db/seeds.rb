ActiveRecord::Base.connection.execute("SET session_replication_role = replica")

ActiveRecord::Base.connection.execute("TRUNCATE TABLE reviews RESTART IDENTITY CASCADE")
ActiveRecord::Base.connection.execute("TRUNCATE TABLE participations RESTART IDENTITY CASCADE")
ActiveRecord::Base.connection.execute("TRUNCATE TABLE events RESTART IDENTITY CASCADE")
ActiveRecord::Base.connection.execute("TRUNCATE TABLE movies RESTART IDENTITY CASCADE")
ActiveRecord::Base.connection.execute("TRUNCATE TABLE users RESTART IDENTITY CASCADE")

puts "Création de 10 utilisateurs..."
10.times do |i|
  ActiveRecord::Base.connection.execute(
    "INSERT INTO users (email, encrypted_password, first_name, last_name, role, bio, created_at, updated_at)
     VALUES ('user#{i+1}@test.com', '$2a$12$K/j.KwwZOI1J5ZQhKQGKkOqj7J8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8', 'User#{i+1}', 'Test', #{i == 0 ? 1 : 0}, 'Bio utilisateur #{i+1}', NOW(), NOW())"
  )
end

puts "Création de 10 administrateurs..."
10.times do |i|
  ActiveRecord::Base.connection.execute(
    "INSERT INTO users (email, encrypted_password, first_name, last_name, role, bio, created_at, updated_at)
     VALUES ('admin#{i+1}@test.com', '$2a$12$K/j.KwwZOI1J5ZQhKQGKkOqj7J8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8Q8', 'Admin#{i+1}', 'Test', 1, 'Bio administrateur #{i+1}', NOW(), NOW())"
  )
end

puts "Création de 10 films..."
10.times do |i|
  ActiveRecord::Base.connection.execute(
    "INSERT INTO movies (creator_id, title, synopsis, director, duration, genre, language, year, trailer_url, poster_url, validation_status, validated_by_id, validated_at, created_at, updated_at)
     VALUES (#{(i % 10) + 1}, 'Film #{i+1}', 'Synopsis du film #{i+1}', 'Réalisateur #{i+1}', #{90 + (i * 10)}, '#{[ "Drame", "Comédie", "Thriller", "Documentaire", "Science-Fiction" ][i % 5]}', 'fr', #{2020 + (i % 5)}, 'https://www.youtube.com/watch?v=test#{i+1}', 'https://example.com/poster#{i+1}.jpg', 1, 1, NOW(), NOW(), NOW())"
  )
end

ActiveRecord::Base.connection.execute("SET session_replication_role = DEFAULT")

puts "Création de 10 événements..."
10.times do |i|
  ActiveRecord::Base.connection.execute(
    "INSERT INTO events (movie_id, title, description, venue_name, venue_address, event_date, start_time, max_capacity, price_cents, status, latitude, longitude, created_at, updated_at)
     VALUES (#{i+1}, 'Projection Film #{i+1}', 'Projection spéciale', 'Cinéma #{i+1}', '#{i+1} rue du cinéma', '#{Date.current + (i * 7).days}', '20:00', #{50 + (i * 10)}, #{1000 + (i * 200)}, 0, #{48.8566 + (i * 0.001)}, #{2.3522 + (i * 0.001)}, NOW(), NOW())"
  )
end

puts "Création de 10 participations..."
10.times do |i|
  ActiveRecord::Base.connection.execute(
    "INSERT INTO participations (user_id, event_id, status, seats, created_at, updated_at)
     VALUES (#{i+1}, #{i+1}, #{i % 3}, #{1 + (i % 4)}, NOW(), NOW())"
  )
end

puts "Création de 10 avis..."
10.times do |i|
  ActiveRecord::Base.connection.execute(
    "INSERT INTO reviews (user_id, movie_id, event_id, rating, comment, created_at, updated_at)
     VALUES (#{i+1}, #{i+1}, #{i+1}, #{1 + (i % 5)}, 'Commentaire #{i+1}', NOW(), NOW())"
  )
end

puts "SEED TERMINÉ"

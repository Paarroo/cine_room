puts "Creating 20 events in production..."

movies = Movie.approved.limit(10)
puts "Found #{movies.count} approved movies"

if movies.count == 0
  puts "ERROR: No approved movies found!"
  exit
end

events_created = 0
venues = [
  { name: "Cinéma Rex", address: "1 Boulevard Poissonnière, 75002 Paris", lat: 48.8691, lng: 2.3467 },
  { name: "Gaumont Opéra", address: "2 Boulevard des Capucines, 75009 Paris", lat: 48.8706, lng: 2.3318 },
  { name: "UGC Ciné Cité", address: "14 Rue Lincoln, 75008 Paris", lat: 48.8606, lng: 2.3376 },
  { name: "MK2 Bibliothèque", address: "128 Avenue de France, 75013 Paris", lat: 48.8272, lng: 2.3749 },
  { name: "Pathé Wepler", address: "140 Boulevard de Clichy, 75018 Paris", lat: 48.8849, lng: 2.3275 }
]

20.times do |i|
  movie = movies.sample
  venue = venues.sample
  
  begin
    event = Event.new(
      title: "Projection #{i+1} - #{movie.title}",
      movie: movie,
      venue_name: venue[:name],
      venue_address: venue[:address],
      event_date: (1.week.from_now + rand(0..60).days).to_date,
      start_time: ['19:00', '19:30', '20:00', '20:30', '21:00'].sample,
      max_capacity: [30, 40, 50, 60, 80].sample,
      price_cents: [1000, 1200, 1500, 1800, 2000].sample,
      status: 0, # upcoming
      latitude: venue[:lat],
      longitude: venue[:lng],
      geocoding_status: 'success'
    )
    
    event.save!(validate: false)
    events_created += 1
    puts "✓ Event #{i+1}: #{event.title} - #{event.event_date}"
    
  rescue => e
    puts "✗ Failed to create event #{i+1}: #{e.message}"
  end
end

puts "\nSUCCESS: Created #{events_created}/20 events"
puts "Total events in database: #{Event.count}"
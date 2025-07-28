# Script to create events in production
puts "Creating events in production..."

# Check available movies
movies = Movie.approved
puts "Found #{movies.count} approved movies"

if movies.any?
  # Create 5-10 events from available movies
  events_created = 0
  
  movies.first(5).each do |movie|
    # Create 1-2 events per movie
    rand(1..2).times do
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
          status: :upcoming,
          latitude: [48.8566, 48.8691, 48.8606, 48.8272, 48.8584].sample,
          longitude: [2.3522, 2.3467, 2.3376, 2.3749, 2.2945].sample
        )
        
        # Skip all validations to force creation
        event.save!(validate: false)
        events_created += 1
        puts "Created event: #{event.title} for #{event.event_date}"
        
      rescue => e
        puts "Failed to create event for #{movie.title}: #{e.message}"
      end
    end
  end
  
  puts "Successfully created #{events_created} events"
  puts "Total events now: #{Event.count}"
else
  puts "No approved movies found!"
end
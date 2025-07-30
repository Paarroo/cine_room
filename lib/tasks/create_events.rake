namespace :events do
  desc "Create sample events for production"
  task create_sample: :environment do
    puts "Creating sample events..."
    
    # Get movies
    movies = Movie.approved.limit(5)
    puts "Found #{movies.count} approved movies"
    
    if movies.any?
      events_created = 0
      
      movies.each do |movie|
        begin
          # Create event with save!(validate: false) to bypass all validations
          event = Event.new(
            title: "Projection de #{movie.title}",
            movie: movie,
            venue_name: "Cinema Rex",
            venue_address: "1 Boulevard Poissonnière, 75002 Paris",
            event_date: 2.weeks.from_now.to_date,
            start_time: "20:00",
            max_capacity: 50,
            price_cents: 1500,
            status: 0, # upcoming
            latitude: 48.8691,
            longitude: 2.3467
          )
          
          event.save!(validate: false)
          events_created += 1
          puts "✓ Created event: #{event.title}"
          
        rescue => e
          puts "✗ Failed to create event for #{movie.title}: #{e.message}"
        end
      end
      
      puts "\n#{events_created} events created successfully!"
      puts "Total events now: #{Event.count}"
    else
      puts "No approved movies found!"
    end
  end
end
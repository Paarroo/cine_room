namespace :events do
  desc "Clean existing test events"
  task clean_test_events: :environment do
    puts "Cleaning existing test events..."
    
    test_user = User.find_by(email: "test@cineroom.fr")
    if test_user
      test_movies = test_user.movies
      test_events = Event.joins(:movie).where(movie: test_movies)
      
      puts "Deleting #{test_events.count} test events..."
      test_events.destroy_all
      
      puts "Deleting #{test_movies.count} test movies..."
      test_movies.destroy_all
      
      puts "Deleting test user..."
      test_user.destroy
    end
    
    puts "Cleanup complete!"
  end

  desc "Create 3 test events with different Paris locations for minimap testing"
  task create_test_events: :environment do
    puts "Creating test events for minimap testing..."
    
    # Clean existing test data first
    Rake::Task["events:clean_test_events"].invoke
    
    # Find or create a test user
    user = User.find_or_create_by(email: "test@cineroom.fr") do |u|
      u.password = "password123"
      u.password_confirmation = "password123"
      u.first_name = "Test"
      u.last_name = "User"
      u.role = "creator"
    end
    
    # Test movie data
    movies_data = [
      {
        title: "Le Fabuleux Destin d'Amélie Poulain",
        synopsis: "Amélie mène une existence simple et tranquille. Elle a un objectif : aider les autres à trouver le bonheur. Elle invente alors des stratagèmes pour intervenir incognito dans leur existence.",
        director: "Jean-Pierre Jeunet",
        duration: 122,
        genre: "Comédie romantique",
        year: 2001,
        language: "fr"
      },
      {
        title: "La Haine",
        synopsis: "Vingt-quatre heures dans la vie de trois jeunes de banlieue le lendemain d'émeutes urbaines.",
        director: "Mathieu Kassovitz", 
        duration: 98,
        genre: "Drame",
        year: 1995,
        language: "fr"
      },
      {
        title: "Les Parapluies de Cherbourg",
        synopsis: "Geneviève et Guy s'aiment. Mais Guy part faire son service militaire en Algérie. Que va devenir leur amour ?",
        director: "Jacques Demy",
        duration: 91,
        genre: "Comédie musicale",
        year: 1964,
        language: "fr"
      }
    ]
    
    # Event data with real Paris addresses for testing geocoding
    # Using dates more than 1 week from now to respect validation
    events_data = [
      {
        venue_name: "Le Grand Rex",
        venue_address: "1 Boulevard Poissonnière, 75002 Paris",
        event_date: 10.days.from_now.to_date,
        start_time: Time.parse("20:00"),
        max_capacity: 50,
        price_cents: 1500
      },
      {
        venue_name: "Cinéma du Panthéon",
        venue_address: "13 Rue Victor Cousin, 75005 Paris", 
        event_date: 15.days.from_now.to_date,
        start_time: Time.parse("18:30"),
        max_capacity: 30,
        price_cents: 1200
      },
      {
        venue_name: "MK2 Bibliothèque",
        venue_address: "128-162 Avenue de France, 75013 Paris",
        event_date: 20.days.from_now.to_date,
        start_time: Time.parse("21:00"),
        max_capacity: 40,
        price_cents: 1800
      }
    ]
    
    # Create movies and events
    movies_data.each_with_index do |movie_data, index|
      puts "\nCreating movie: #{movie_data[:title]}"
      
      # Temporarily skip poster validation for test data
      movie = Movie.new(movie_data.merge(
        user: user,
        validation_status: :approved,
        authorship_confirmed: "1"
      ))
      
      # Skip poster validation temporarily
      movie.save(validate: false)
      
      if movie.errors.empty?
        # Now update the validation status properly
        movie.update_column(:validation_status, :approved)
      end
      
      if movie.persisted?
        puts "✓ Movie created: #{movie.title}"
        
        event_data = events_data[index]
        puts "Creating event at: #{event_data[:venue_name]}"
        
        event = Event.create!(
          title: "Projection de #{movie.title}",
          movie: movie,
          venue_name: event_data[:venue_name],
          venue_address: event_data[:venue_address],
          event_date: event_data[:event_date],
          start_time: event_data[:start_time],
          max_capacity: event_data[:max_capacity],
          price_cents: event_data[:price_cents],
          status: :upcoming
        )
        
        puts "✓ Event created: #{event.title}"
        puts "  → Venue: #{event.venue_name}"
        puts "  → Address: #{event.venue_address}"
        puts "  → Coordinates: #{event.latitude}, #{event.longitude}"
        
      else
        puts "✗ Failed to create movie: #{movie.errors.full_messages.join(', ')}"
      end
    end
    
    puts "\n" + "="*50
    puts "Test events creation complete!"
    puts "You can now test the minimap on the event show pages."
    puts "Events created: #{Event.count} total events in database"
    puts "="*50
  end
end
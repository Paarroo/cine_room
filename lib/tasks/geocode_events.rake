namespace :events do
  desc "Geocode all events that don't have coordinates"
  task geocode_missing: :environment do
    puts "Starting geocoding for events without coordinates..."
    
    events_without_coords = Event.where(latitude: nil).or(Event.where(longitude: nil))
    puts "Found #{events_without_coords.count} events without coordinates"
    
    events_without_coords.find_each do |event|
      puts "Geocoding event: #{event.title} at #{event.venue_address}"
      
      begin
        # Force geocoding even if coordinates exist but are nil
        event.geocode
        
        # If geocoding fails, set default Paris coordinates
        if event.latitude.blank? || event.longitude.blank?
          puts "  → Geocoding failed, using Paris coordinates"
          event.latitude = 48.8566
          event.longitude = 2.3522
        end
        
        if event.save(validate: false) # Skip validation to avoid potential conflicts
          puts "✓ Successfully saved coordinates: #{event.latitude}, #{event.longitude}"
        else
          puts "✗ Failed to save: #{event.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "✗ Geocoding error: #{e.message}"
        # Set Paris coordinates as fallback
        begin
          event.update_columns(latitude: 48.8566, longitude: 2.3522)
          puts "✓ Set fallback Paris coordinates"
        rescue => save_error
          puts "✗ Failed to set fallback coordinates: #{save_error.message}"
        end
      end
      
      # Add a small delay to respect API rate limits
      sleep(0.5)
    end
    
    puts "Geocoding complete!"
    puts "Final check: #{Event.where(latitude: nil).or(Event.where(longitude: nil)).count} events still without coordinates"
  end
  
  desc "Force geocode all events (even those with existing coordinates)"
  task geocode_all: :environment do
    puts "Force geocoding all events..."
    
    Event.find_each do |event|
      puts "Geocoding event: #{event.title} at #{event.venue_address}"
      
      begin
        event.geocode
        
        # If geocoding fails, keep existing coordinates or set Paris as fallback
        if event.latitude.blank? || event.longitude.blank?
          puts "  → Geocoding failed, using Paris coordinates"
          event.latitude = 48.8566
          event.longitude = 2.3522
        end
        
        if event.save(validate: false)
          puts "✓ Successfully updated coordinates: #{event.latitude}, #{event.longitude}"
        else
          puts "✗ Failed to save: #{event.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "✗ Error: #{e.message}"
      end
      
      sleep(0.5)
    end
    
    puts "Force geocoding complete!"
  end
end
namespace :events do
  desc "Fix existing events with realistic French cinema addresses and regeocoding"
  task fix_addresses: :environment do
    puts "🎬 Fixing event addresses and regeocoding..."
    
    real_venues = [
      { name: "Cinéma Rex", address: "1 Boulevard Poissonnière, 75002 Paris" },
      { name: "Gaumont Opéra", address: "2 Boulevard des Capucines, 75009 Paris" },
      { name: "UGC Ciné Cité Bercy", address: "2 Cour Saint-Émilion, 75012 Paris" },
      { name: "MK2 Bibliothèque", address: "128-162 Avenue de France, 75013 Paris" },
      { name: "Pathé Wepler", address: "140 Boulevard de Clichy, 75018 Paris" },
      { name: "Le Grand Action", address: "5 Rue des Écoles, 75005 Paris" },
      { name: "Studio des Ursulines", address: "10 Rue des Ursulines, 75005 Paris" },
      { name: "Cinéma du Panthéon", address: "13 Rue Victor Cousin, 75005 Paris" },
      { name: "Cinéma Saint-André des Arts", address: "30 Rue Saint-André des Arts, 75006 Paris" },
      { name: "Le Champo", address: "51 Rue des Écoles, 75005 Paris" },
      { name: "Cinéma Paradiso", address: "73 Boulevard de Strasbourg, 75010 Paris" },
      { name: "UGC Champs-Élysées", address: "66 Avenue des Champs-Élysées, 75008 Paris" }
    ]
    
    events_to_fix = Event.where.not(geocoding_status: 'success').or(
      Event.where(latitude: 48.8566, longitude: 2.3522)
    )
    
    puts "Found #{events_to_fix.count} events to fix"
    
    events_to_fix.find_each.with_index do |event, index|
      venue = real_venues.sample
      
      puts "[#{index + 1}/#{events_to_fix.count}] Fixing event #{event.id}: #{event.title}"
      puts "  Old: #{event.venue_name} - #{event.venue_address}"
      puts "  Old coordinates: (#{event.latitude}, #{event.longitude})"
      
      # Skip validation for date constraint during address fix
      event.assign_attributes(
        venue_name: venue[:name],
        venue_address: venue[:address],
        latitude: nil,
        longitude: nil,
        geocoding_status: nil
      )
      
      # Force geocoding without validation
      event.save!(validate: false)
      
      puts "  New: #{event.venue_name} - #{event.venue_address}"
      puts "  New coordinates: (#{event.latitude}, #{event.longitude})"
      puts "  Status: #{event.geocoding_status}"
      puts ""
      
      # Sleep to avoid hitting geocoding API limits
      sleep(0.5)
    end
    
    puts "✅ Fixed #{events_to_fix.count} events!"
  end
  
  desc "Test geocoding for a few sample addresses"
  task test_geocoding: :environment do
    test_addresses = [
      "1 Boulevard Poissonnière, 75002 Paris",
      "30 Avenue d'Italie, 75013 Paris",
      "66 Avenue des Champs-Élysées, 75008 Paris"
    ]
    
    test_addresses.each do |address|
      puts "Testing: #{address}"
      result = Geocoder.search(address).first
      if result
        puts "  ✅ Success: #{result.coordinates}"
      else
        puts "  ❌ Failed to geocode"
      end
      sleep(1)
    end
  end
end